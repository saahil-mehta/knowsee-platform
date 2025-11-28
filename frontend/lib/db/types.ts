/**
 * Database type definitions.
 *
 * These types match the backend SQLAlchemy models and are used
 * throughout the frontend for type safety when calling the backend API.
 */

import type { ArtifactKind } from "@/components/artifact";
import type { VisibilityType } from "@/components/visibility-selector";
import type { AppUsage } from "@/lib/usage";

export type User = {
  id: string;
  email: string;
  password: string | null;
};

export type Chat = {
  id: string;
  createdAt: Date;
  title: string;
  userId: string;
  visibility: VisibilityType;
  lastContext: AppUsage | null;
};

export type DBMessage = {
  id: string;
  chatId: string;
  role: string;
  parts: Array<{ type: string; text?: string; [key: string]: unknown }>;
  attachments: Record<string, unknown>[];
  createdAt: Date;
};

export type Vote = {
  chatId: string;
  messageId: string;
  isUpvoted: boolean;
};

export type Document = {
  id: string;
  createdAt: Date;
  title: string;
  content: string | null;
  kind: ArtifactKind;
  userId: string;
};

export type Suggestion = {
  id: string;
  documentId: string;
  documentCreatedAt: Date;
  originalText: string;
  suggestedText: string;
  description: string | null;
  isResolved: boolean;
  userId: string;
  createdAt: Date;
};

export type Stream = {
  id: string;
  chatId: string;
  createdAt: Date;
};
