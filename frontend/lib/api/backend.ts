/**
 * Backend API client for Python FastAPI database operations.
 *
 * This module provides type-safe fetch wrappers for all database
 * endpoints exposed by the Python backend.
 */

import "server-only";

const BACKEND_URL = process.env.BACKEND_URL || "http://localhost:8000";

/**
 * Custom error class for backend API errors.
 */
export class BackendAPIError extends Error {
  status: number;
  statusText: string;

  constructor(status: number, statusText: string, message: string) {
    super(message);
    this.name = "BackendAPIError";
    this.status = status;
    this.statusText = statusText;
  }
}

/**
 * Generic fetch wrapper for backend API calls.
 *
 * @param endpoint - API endpoint (e.g., "/api/db/users")
 * @param options - Fetch options
 * @returns Parsed JSON response
 * @throws BackendAPIError on non-2xx responses
 */
export async function backendFetch<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const url = `${BACKEND_URL}${endpoint}`;

  const response = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options?.headers,
    },
  });

  if (!response.ok) {
    const errorText = await response.text().catch(() => "Unknown error");
    throw new BackendAPIError(
      response.status,
      response.statusText,
      `Backend API error: ${response.status} ${response.statusText} - ${errorText}`
    );
  }

  // Handle empty responses
  const text = await response.text();
  if (!text) {
    return null as T;
  }

  return JSON.parse(text) as T;
}

/**
 * POST request helper.
 */
export function backendPost<T, B = unknown>(
  endpoint: string,
  body: B
): Promise<T> {
  return backendFetch<T>(endpoint, {
    method: "POST",
    body: JSON.stringify(body),
  });
}

/**
 * PATCH request helper.
 */
export function backendPatch<T, B = unknown>(
  endpoint: string,
  body: B
): Promise<T> {
  return backendFetch<T>(endpoint, {
    method: "PATCH",
    body: JSON.stringify(body),
  });
}

/**
 * DELETE request helper.
 */
export function backendDelete<T>(endpoint: string): Promise<T> {
  return backendFetch<T>(endpoint, {
    method: "DELETE",
  });
}
