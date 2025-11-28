/**
 * Create a user via the backend API.
 *
 * Usage:
 *   npx tsx scripts/create-user.ts [email] [password]
 *
 * Requires the backend to be running at BACKEND_URL (default: http://localhost:8000)
 */

import { config } from "dotenv";

config({
  path: ".env.local",
});

const email = process.argv[2] || "test@example.com";
const password = process.argv[3] || "password";

const BACKEND_URL = process.env.BACKEND_URL || "http://localhost:8000";

async function createUser() {
  console.log(`Creating user: ${email}`);

  const response = await fetch(
    `${BACKEND_URL}/api/db/users?email=${encodeURIComponent(email)}&password=${encodeURIComponent(password)}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
    }
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Failed to create user: ${response.status} ${response.statusText} - ${text}`
    );
  }

  const user = await response.json();
  console.log("User created successfully:", user.email);
  process.exit(0);
}

createUser().catch((err) => {
  console.error("Failed to create user");
  console.error(err);
  process.exit(1);
});
