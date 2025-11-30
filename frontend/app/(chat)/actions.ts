"use server";

import type { UIMessage } from "ai";
import { cookies } from "next/headers";
import type { VisibilityType } from "@/components/visibility-selector";
import {
  deleteMessagesByChatIdAfterTimestamp,
  getMessageById,
  updateChatVisibilityById,
} from "@/lib/db/queries";
import { getTextFromMessage } from "@/lib/utils";

const BACKEND_URL = process.env.BACKEND_URL || "http://localhost:8000";

export async function saveChatModelAsCookie(model: string) {
  const cookieStore = await cookies();
  cookieStore.set("chat-model", model);
}

export async function generateTitleFromUserMessage({
  message,
}: {
  message: UIMessage;
}) {
  const messageText = getTextFromMessage(message);

  try {
    const response = await fetch(`${BACKEND_URL}/api/title`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message: messageText }),
    });

    if (!response.ok) {
      console.error("Title generation failed:", response.status);
      // Fallback to truncated message
      return messageText.slice(0, 50) + (messageText.length > 50 ? "..." : "");
    }

    const data = await response.json();
    return data.title;
  } catch (error) {
    console.error("Title generation error:", error);
    // Fallback to truncated message
    return messageText.slice(0, 50) + (messageText.length > 50 ? "..." : "");
  }
}

export async function deleteTrailingMessages({ id }: { id: string }) {
  const [message] = await getMessageById({ id });

  await deleteMessagesByChatIdAfterTimestamp({
    chatId: message.chatId,
    timestamp: message.createdAt,
  });
}

export async function updateChatVisibility({
  chatId,
  visibility,
}: {
  chatId: string;
  visibility: VisibilityType;
}) {
  await updateChatVisibilityById({ chatId, visibility });
}
