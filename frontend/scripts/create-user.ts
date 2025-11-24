import { config } from "dotenv";
import { hash } from "bcrypt-ts";
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import { user } from "../lib/db/schema";

config({
  path: ".env.local",
});

const email = process.argv[2] || "test@example.com";
const password = process.argv[3] || "password";

async function createUser() {
  if (!process.env.POSTGRES_URL) {
    throw new Error("POSTGRES_URL is not defined");
  }

  const connection = postgres(process.env.POSTGRES_URL, { max: 1 });
  const db = drizzle(connection);

  console.log(`Creating user: ${email}`);

  const hashedPassword = await hash(password, 10);

  await db.insert(user).values({
    email,
    password: hashedPassword,
  });

  console.log("User created successfully");
  await connection.end();
  process.exit(0);
}

createUser().catch((err) => {
  console.error("Failed to create user");
  console.error(err);
  process.exit(1);
});
