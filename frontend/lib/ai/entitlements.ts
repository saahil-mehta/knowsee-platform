import type { ChatModel } from "./models";

type Entitlements = {
  maxMessagesPerDay: number;
  availableChatModelIds: ChatModel["id"][];
};

export const userEntitlements: Entitlements = {
  maxMessagesPerDay: 100,
  availableChatModelIds: ["chat-model", "chat-model-reasoning"],
};
