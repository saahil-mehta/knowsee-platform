export const DEFAULT_CHAT_MODEL: string = "chat-model";

export type ChatModel = {
  id: string;
  name: string;
  description: string;
};

// Model display names for the UI - actual inference happens via Python backend
export const chatModels: ChatModel[] = [
  {
    id: "chat-model",
    name: "Gemini 2.5 Flash",
    description: "LangGraph chatbot powered by Gemini 2.5 Flash via Vertex AI",
  },
];
