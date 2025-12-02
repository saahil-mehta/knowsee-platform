import { createDocumentHandler } from "@/lib/artifacts/server";

export const textDocumentHandler = createDocumentHandler<"text">({
  kind: "text",
  onCreateDocument: () => {
    throw new Error("Document creation is disabled - tools have been removed");
  },
  onUpdateDocument: () => {
    throw new Error("Document update is disabled - tools have been removed");
  },
});
