import { describe, expect, it } from "vitest";
import {
  cn,
  generateUUID,
  getMostRecentUserMessage,
  getTextFromMessage,
  getTrailingMessageId,
  sanitizeText,
} from "@/lib/utils";

describe("cn (classname merger)", () => {
  it("merges class names correctly", () => {
    expect(cn("foo", "bar")).toBe("foo bar");
  });

  it("handles conditional classes", () => {
    expect(cn("foo", false && "bar", "baz")).toBe("foo baz");
  });

  it("merges tailwind classes and resolves conflicts", () => {
    expect(cn("px-2 py-1", "px-4")).toBe("py-1 px-4");
  });

  it("handles empty inputs", () => {
    expect(cn()).toBe("");
  });

  it("handles undefined and null", () => {
    expect(cn("foo", undefined, null, "bar")).toBe("foo bar");
  });
});

describe("generateUUID", () => {
  it("generates a valid UUID v4 format", () => {
    const uuid = generateUUID();
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    expect(uuid).toMatch(uuidRegex);
  });

  it("generates unique UUIDs", () => {
    const uuids = new Set(Array.from({ length: 100 }, () => generateUUID()));
    expect(uuids.size).toBe(100);
  });

  it("always has 4 as version number", () => {
    const uuid = generateUUID();
    expect(uuid[14]).toBe("4");
  });
});

describe("getMostRecentUserMessage", () => {
  it("returns the last user message", () => {
    const messages = [
      { id: "1", role: "user", parts: [], metadata: {} },
      { id: "2", role: "assistant", parts: [], metadata: {} },
      { id: "3", role: "user", parts: [], metadata: {} },
    ];
    const result = getMostRecentUserMessage(messages as any);
    expect(result?.id).toBe("3");
  });

  it("returns undefined when no user messages exist", () => {
    const messages = [
      { id: "1", role: "assistant", parts: [], metadata: {} },
      { id: "2", role: "assistant", parts: [], metadata: {} },
    ];
    const result = getMostRecentUserMessage(messages as any);
    expect(result).toBeUndefined();
  });

  it("returns undefined for empty array", () => {
    const result = getMostRecentUserMessage([]);
    expect(result).toBeUndefined();
  });
});

describe("sanitizeText", () => {
  it("removes function call marker", () => {
    const text = "Hello <has_function_call> world";
    expect(sanitizeText(text)).toBe("Hello  world");
  });

  it("handles text without marker", () => {
    const text = "Hello world";
    expect(sanitizeText(text)).toBe("Hello world");
  });

  it("handles empty string", () => {
    expect(sanitizeText("")).toBe("");
  });
});

describe("getTrailingMessageId", () => {
  it("returns the id of the last message", () => {
    const messages = [
      { id: "msg-1", role: "user" },
      { id: "msg-2", role: "assistant" },
    ];
    expect(getTrailingMessageId({ messages: messages as any })).toBe("msg-2");
  });

  it("returns null for empty messages array", () => {
    expect(getTrailingMessageId({ messages: [] })).toBeNull();
  });
});

describe("getTextFromMessage", () => {
  it("extracts text from message parts", () => {
    const message = {
      id: "1",
      role: "user",
      parts: [
        { type: "text", text: "Hello " },
        { type: "text", text: "world" },
      ],
    };
    expect(getTextFromMessage(message as any)).toBe("Hello world");
  });

  it("ignores non-text parts", () => {
    const message = {
      id: "1",
      role: "user",
      parts: [
        { type: "text", text: "Hello" },
        { type: "tool-invocation", toolName: "test" },
        { type: "text", text: " world" },
      ],
    };
    expect(getTextFromMessage(message as any)).toBe("Hello world");
  });

  it("returns empty string for message with no text parts", () => {
    const message = {
      id: "1",
      role: "user",
      parts: [{ type: "tool-invocation", toolName: "test" }],
    };
    expect(getTextFromMessage(message as any)).toBe("");
  });
});
