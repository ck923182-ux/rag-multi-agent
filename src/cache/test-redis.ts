import { connectRedis, redisClient } from "./redis.js";

async function main() {
  try {
    await connectRedis();

    await redisClient.set("rag:test", "Redis connection works");

    const value = await redisClient.get("rag:test");

    console.log("✅ Redis test value:", value);

    await redisClient.quit();
  } catch (error) {
    console.error("❌ Redis connection failed:", error);
    process.exit(1);
  }
}

main();