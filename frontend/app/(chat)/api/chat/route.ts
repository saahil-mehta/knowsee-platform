import { createUIMessageStream, createUIMessageStreamResponse } from "ai";
import { after } from "next/server";
import {
  createResumableStreamContext,
  type ResumableStreamContext,
} from "resumable-stream";
import { auth } from "@/app/(auth)/auth";
import type { VisibilityType } from "@/components/visibility-selector";
import { userEntitlements } from "@/lib/ai/entitlements";
import type { ChatModel } from "@/lib/ai/models";
import {
  createStreamId,
  deleteChatById,
  getChatById,
  getMessageCountByUserId,
  getMessagesByChatId,
  saveChat,
  saveMessages,
} from "@/lib/db/queries";
import type { DBMessage } from "@/lib/db/types";
import { ChatSDKError } from "@/lib/errors";
import type { ChatMessage } from "@/lib/types";
import { convertToUIMessages, generateUUID } from "@/lib/utils";
import { generateTitleFromUserMessage } from "../../actions";
import { type PostRequestBody, postRequestBodySchema } from "./schema";

export const maxDuration = 60;

const BACKEND_URL = process.env.BACKEND_URL || "http://localhost:8000";

let globalStreamContext: ResumableStreamContext | null = null;

export function getStreamContext() {
  if (!globalStreamContext) {
    try {
      globalStreamContext = createResumableStreamContext({
        waitUntil: after,
      });
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      if (errorMessage.includes("REDIS_URL")) {
        console.log(
          " > Resumable streams are disabled due to missing REDIS_URL"
        );
      } else {
        console.error(error);
      }
    }
  }

  return globalStreamContext;
}

/**
 * Parse SSE stream from backend and extract text content.
 */
async function* parseBackendSSE(
  response: Response
): AsyncGenerator<{ type: string; text?: string; delta?: string }> {
  const reader = response.body?.getReader();
  if (!reader) {
    return;
  }

  const decoder = new TextDecoder();
  let buffer = "";

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split("\n");
      buffer = lines.pop() || "";

      for (const line of lines) {
        if (line.startsWith("data: ")) {
          const data = line.slice(6);
          if (data === "[DONE]") {
            continue;
          }

          try {
            yield JSON.parse(data);
          } catch {
            // Not JSON, skip
          }
        }
      }
    }
  } finally {
    reader.releaseLock();
  }
}

export async function POST(request: Request) {
  let requestBody: PostRequestBody;

  try {
    const json = await request.json();
    requestBody = postRequestBodySchema.parse(json);
  } catch (_) {
    return new ChatSDKError("bad_request:api").toResponse();
  }

  try {
    const {
      id,
      message,
      selectedChatModel,
      selectedVisibilityType,
    }: {
      id: string;
      message: ChatMessage;
      selectedChatModel: ChatModel["id"];
      selectedVisibilityType: VisibilityType;
    } = requestBody;

    const session = await auth();

    if (!session?.user) {
      return new ChatSDKError("unauthorized:chat").toResponse();
    }

    const messageCount = await getMessageCountByUserId({
      id: session.user.id,
      differenceInHours: 24,
    });

    if (messageCount > userEntitlements.maxMessagesPerDay) {
      return new ChatSDKError("rate_limit:chat").toResponse();
    }

    const chat = await getChatById({ id });
    let messagesFromDb: DBMessage[] = [];

    if (chat) {
      if (chat.userId !== session.user.id) {
        return new ChatSDKError("forbidden:chat").toResponse();
      }
      messagesFromDb = await getMessagesByChatId({ id });
    } else {
      const title = await generateTitleFromUserMessage({
        message,
      });

      await saveChat({
        id,
        userId: session.user.id,
        title,
        visibility: selectedVisibilityType,
      });
    }

    // Save the user message
    await saveMessages({
      messages: [
        {
          chatId: id,
          id: message.id,
          role: "user",
          parts: message.parts,
          attachments: [],
          createdAt: new Date(),
        },
      ],
    });

    const streamId = generateUUID();
    await createStreamId({ streamId, chatId: id });

    // Build message history for backend
    const uiMessages = [...convertToUIMessages(messagesFromDb), message];
    const backendMessages = uiMessages.map((msg) => ({
      role: msg.role,
      parts: msg.parts,
    }));

    // Call backend streaming endpoint
    const backendResponse = await fetch(`${BACKEND_URL}/api/chat`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        id: message.id,
        messages: backendMessages,
        selectedChatModel,
        selectedVisibilityType,
      }),
    });

    if (!backendResponse.ok) {
      const errorText = await backendResponse
        .text()
        .catch(() => "Unknown error");
      console.error("Backend chat error:", backendResponse.status, errorText);
      return new ChatSDKError("offline:chat").toResponse();
    }

    if (!backendResponse.body) {
      return new ChatSDKError("offline:chat").toResponse();
    }

    // Track accumulated text for saving
    let accumulatedText = "";
    const messageId = generateUUID();

    // Create UI message stream that wraps backend response
    const stream = createUIMessageStream({
      execute: async ({ writer }) => {
        // Start the message
        writer.write({
          type: "start",
          messageId,
        });

        // Start a text block
        writer.write({
          type: "text-start",
          id: messageId,
        });

        for await (const event of parseBackendSSE(backendResponse)) {
          if (event.type === "text-delta" && event.delta) {
            accumulatedText += event.delta;
            writer.write({
              type: "text-delta",
              id: messageId,
              delta: event.delta,
            });
          }
        }

        // End the text block
        writer.write({
          type: "text-end",
          id: messageId,
        });
      },
      onFinish: async () => {
        // Save assistant message
        if (accumulatedText) {
          await saveMessages({
            messages: [
              {
                chatId: id,
                id: messageId,
                role: "assistant",
                parts: [{ type: "text", text: accumulatedText }],
                attachments: [],
                createdAt: new Date(),
              },
            ],
          });
        }
      },
      onError: () => {
        return "Oops, an error occurred!";
      },
    });

    return createUIMessageStreamResponse({ stream });
  } catch (error) {
    const vercelId = request.headers.get("x-vercel-id");

    if (error instanceof ChatSDKError) {
      return error.toResponse();
    }

    console.error("Unhandled error in chat API:", error, { vercelId });
    return new ChatSDKError("offline:chat").toResponse();
  }
}

export async function DELETE(request: Request) {
  const { searchParams } = new URL(request.url);
  const id = searchParams.get("id");

  if (!id) {
    return new ChatSDKError("bad_request:api").toResponse();
  }

  const session = await auth();

  if (!session?.user) {
    return new ChatSDKError("unauthorized:chat").toResponse();
  }

  const chat = await getChatById({ id });

  if (chat?.userId !== session.user.id) {
    return new ChatSDKError("forbidden:chat").toResponse();
  }

  const deletedChat = await deleteChatById({ id });

  return Response.json(deletedChat, { status: 200 });
}
