import { createGoogleGenerativeAI } from "@ai-sdk/google";
import {
  customProvider,
  extractReasoningMiddleware,
  wrapLanguageModel,
} from "ai";

const google = createGoogleGenerativeAI({
  apiKey: process.env.GOOGLE_GENERATIVE_AI_API_KEY,
});

export const myProvider = customProvider({
  languageModels: {
    "chat-model": google("gemini-2.5-flash-lite"),
    "chat-model-reasoning": wrapLanguageModel({
      model: google("gemini-2.5-flash-lite"),
      middleware: extractReasoningMiddleware({ tagName: "think" }),
    }),
    "title-model": google("gemini-2.5-flash-lite"),
    "artifact-model": google("gemini-2.5-flash-lite"),
  },
});
