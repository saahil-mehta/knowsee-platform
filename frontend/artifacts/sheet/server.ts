import { createDocumentHandler } from "@/lib/artifacts/server";

export const sheetDocumentHandler = createDocumentHandler<"sheet">({
  kind: "sheet",
  onCreateDocument: () => {
    throw new Error("Document creation is disabled - tools have been removed");
  },
  onUpdateDocument: () => {
    throw new Error("Document update is disabled - tools have been removed");
  },
});
