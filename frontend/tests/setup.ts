/// <reference types="@testing-library/jest-dom/vitest" />
import "@testing-library/dom";
import "@testing-library/jest-dom/vitest";
// biome-ignore lint/performance/noNamespaceImport: Required for expect.extend() pattern
import * as matchers from "@testing-library/jest-dom/matchers";
import { cleanup } from "@testing-library/react";
import { afterEach, expect } from "vitest";

// Extend Vitest's expect with jest-dom matchers
expect.extend(matchers);

// Cleanup after each test
afterEach(() => {
  cleanup();
});
