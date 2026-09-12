import { testDatabaseConnection } from "./postgres.js";

async function main() {
  try {
    await testDatabaseConnection();
  } catch (error) {
    console.error("PostgreSQL connection failed:", error);
    process.exit(1);
  }
}

main();