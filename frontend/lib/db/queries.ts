/**
 * Database query functions using Python backend API.
 *
 * This module provides the same interface as the original Drizzle-based
 * queries, but delegates all database operations to the Python backend.
 */

import "server-only";

import type { ArtifactKind } from "@/components/artifact";
import type { VisibilityType } from "@/components/visibility-selector";

import {
  BackendAPIError,
  backendDelete,
  backendFetch,
  backendPatch,
  backendPost,
} from "@/lib/api/backend";
import { ChatSDKError } from "../errors";
import type { AppUsage } from "../usage";
import type { Chat, DBMessage, Document, Suggestion, User } from "./types";

// ==============================================================================
// USER QUERIES
// ==============================================================================

export async function getUser(email: string): Promise<User[]> {
  try {
    return await backendFetch<User[]>(
      `/api/db/users?email=${encodeURIComponent(email)}`
    );
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get user by email: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get user by email"
    );
  }
}

export async function createUser(email: string, password: string) {
  try {
    return await backendFetch<User>(
      `/api/db/users?email=${encodeURIComponent(email)}&password=${encodeURIComponent(password)}`,
      { method: "POST" }
    );
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to create user: ${error.message}`
      );
    }
    throw new ChatSDKError("bad_request:database", "Failed to create user");
  }
}

export async function createGuestUser() {
  try {
    const result = await backendPost<{ id: string; email: string }>(
      "/api/db/users/guest",
      {}
    );
    return [result];
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to create guest user: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to create guest user"
    );
  }
}

// ==============================================================================
// CHAT QUERIES
// ==============================================================================

export async function saveChat({
  id,
  userId,
  title,
  visibility,
}: {
  id: string;
  userId: string;
  title: string;
  visibility: VisibilityType;
}) {
  try {
    return await backendPost<Chat>("/api/db/chats", {
      id,
      userId,
      title,
      visibility,
    });
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to save chat: ${error.message}`
      );
    }
    throw new ChatSDKError("bad_request:database", "Failed to save chat");
  }
}

export async function deleteChatById({ id }: { id: string }) {
  try {
    const result = await backendDelete<Chat | null>(`/api/db/chats/${id}`);
    return result;
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to delete chat by id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to delete chat by id"
    );
  }
}

export async function deleteAllChatsByUserId({ userId }: { userId: string }) {
  try {
    return await backendDelete<{ deletedCount: number }>(
      `/api/db/chats/user/${userId}`
    );
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to delete all chats by user id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to delete all chats by user id"
    );
  }
}

export async function getChatsByUserId({
  id,
  limit,
  startingAfter,
  endingBefore,
}: {
  id: string;
  limit: number;
  startingAfter: string | null;
  endingBefore: string | null;
}) {
  try {
    const params = new URLSearchParams({
      userId: id,
      limit: String(limit),
    });
    if (startingAfter) {
      params.set("starting_after", startingAfter);
    }
    if (endingBefore) {
      params.set("ending_before", endingBefore);
    }

    return await backendFetch<{ chats: Chat[]; hasMore: boolean }>(
      `/api/db/chats?${params.toString()}`
    );
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get chats by user id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get chats by user id"
    );
  }
}

export async function getChatById({ id }: { id: string }) {
  try {
    const result = await backendFetch<Chat | null>(`/api/db/chats/${id}`);
    return result;
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get chat by id: ${error.message}`
      );
    }
    throw new ChatSDKError("bad_request:database", "Failed to get chat by id");
  }
}

// ==============================================================================
// MESSAGE QUERIES
// ==============================================================================

export async function saveMessages({ messages }: { messages: DBMessage[] }) {
  try {
    return await backendPost<DBMessage[]>("/api/db/messages", messages);
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to save messages: ${error.message}`
      );
    }
    throw new ChatSDKError("bad_request:database", "Failed to save messages");
  }
}

export async function getMessagesByChatId({ id }: { id: string }) {
  try {
    return await backendFetch<DBMessage[]>(`/api/db/messages/${id}`);
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get messages by chat id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get messages by chat id"
    );
  }
}

export async function voteMessage({
  chatId,
  messageId,
  type,
}: {
  chatId: string;
  messageId: string;
  type: "up" | "down";
}) {
  try {
    return await backendPatch<{ success: boolean }>("/api/db/votes", {
      chatId,
      messageId,
      type,
    });
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to vote message: ${error.message}`
      );
    }
    throw new ChatSDKError("bad_request:database", "Failed to vote message");
  }
}

export async function getVotesByChatId({ id }: { id: string }) {
  try {
    return await backendFetch<
      Array<{ chatId: string; messageId: string; isUpvoted: boolean }>
    >(`/api/db/votes/${id}`);
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get votes by chat id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get votes by chat id"
    );
  }
}

// ==============================================================================
// DOCUMENT QUERIES
// ==============================================================================

export async function saveDocument({
  id,
  title,
  kind,
  content,
  userId,
}: {
  id: string;
  title: string;
  kind: ArtifactKind;
  content: string;
  userId: string;
}) {
  try {
    return await backendPost<Document[]>("/api/db/documents", {
      id,
      title,
      kind,
      content,
      userId,
    });
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to save document: ${error.message}`
      );
    }
    throw new ChatSDKError("bad_request:database", "Failed to save document");
  }
}

export async function getDocumentsById({ id }: { id: string }) {
  try {
    return await backendFetch<Document[]>(`/api/db/documents/${id}`);
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get documents by id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get documents by id"
    );
  }
}

export async function getDocumentById({ id }: { id: string }) {
  try {
    return await backendFetch<Document | null>(
      `/api/db/documents/${id}/latest`
    );
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get document by id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get document by id"
    );
  }
}

export async function deleteDocumentsByIdAfterTimestamp({
  id,
  timestamp,
}: {
  id: string;
  timestamp: Date;
}) {
  try {
    return await backendDelete<Document[]>(
      `/api/db/documents/${id}?timestamp=${timestamp.toISOString()}`
    );
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to delete documents by id after timestamp: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to delete documents by id after timestamp"
    );
  }
}

// ==============================================================================
// SUGGESTION QUERIES
// ==============================================================================

export async function saveSuggestions({
  suggestions,
}: {
  suggestions: Suggestion[];
}) {
  try {
    return await backendPost<Suggestion[]>("/api/db/suggestions", suggestions);
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to save suggestions: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to save suggestions"
    );
  }
}

export async function getSuggestionsByDocumentId({
  documentId,
}: {
  documentId: string;
}) {
  try {
    return await backendFetch<Suggestion[]>(
      `/api/db/suggestions/${documentId}`
    );
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get suggestions by document id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get suggestions by document id"
    );
  }
}

// ==============================================================================
// MESSAGE HELPERS
// ==============================================================================

export async function getMessageById({ id }: { id: string }) {
  try {
    return await backendFetch<DBMessage[]>(`/api/db/messages/single/${id}`);
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get message by id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get message by id"
    );
  }
}

export async function deleteMessagesByChatIdAfterTimestamp({
  chatId,
  timestamp,
}: {
  chatId: string;
  timestamp: Date;
}) {
  try {
    return await backendDelete<{ success: boolean }>(
      `/api/db/messages/${chatId}?timestamp=${timestamp.toISOString()}`
    );
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to delete messages by chat id after timestamp: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to delete messages by chat id after timestamp"
    );
  }
}

export async function updateChatVisibilityById({
  chatId,
  visibility,
}: {
  chatId: string;
  visibility: "private" | "public";
}) {
  try {
    return await backendPatch<{ success: boolean }>(
      `/api/db/chats/${chatId}/visibility?visibility=${visibility}`,
      {}
    );
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to update chat visibility by id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to update chat visibility by id"
    );
  }
}

export async function updateChatLastContextById({
  chatId,
  context,
}: {
  chatId: string;
  context: AppUsage;
}) {
  try {
    return await backendPatch<{ success: boolean }>(
      `/api/db/chats/${chatId}/context`,
      context
    );
  } catch (error) {
    // Match original behavior - warn but don't throw
    console.warn("Failed to update lastContext for chat", chatId, error);
    return;
  }
}

export async function getMessageCountByUserId({
  id,
  differenceInHours,
}: {
  id: string;
  differenceInHours: number;
}) {
  try {
    const result = await backendFetch<{ count: number }>(
      `/api/db/messages/count/${id}?hours=${differenceInHours}`
    );
    return result.count;
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get message count by user id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get message count by user id"
    );
  }
}

// ==============================================================================
// STREAM QUERIES
// ==============================================================================

export async function createStreamId({
  streamId,
  chatId,
}: {
  streamId: string;
  chatId: string;
}) {
  try {
    await backendPost<{ success: boolean }>("/api/db/streams", {
      streamId,
      chatId,
    });
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to create stream id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to create stream id"
    );
  }
}

export async function getStreamIdsByChatId({ chatId }: { chatId: string }) {
  try {
    return await backendFetch<string[]>(`/api/db/streams/${chatId}`);
  } catch (error) {
    if (error instanceof BackendAPIError) {
      throw new ChatSDKError(
        "bad_request:database",
        `Failed to get stream ids by chat id: ${error.message}`
      );
    }
    throw new ChatSDKError(
      "bad_request:database",
      "Failed to get stream ids by chat id"
    );
  }
}
