import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),

  PORT: z.coerce.number().int().positive().default(3000),

  DATABASE_URL: z.string().min(1, "DATABASE_URL is required"),
  

  // REDIS_URL: z.string().min(1, "REDIS_URL is required"),

  // LLM_PROVIDER: z.string().min(1, "LLM_PROVIDER is required"),

  // LLM_MODEL: z.string().min(1, "LLM_MODEL is required"),

  // ANTHROPIC_API_KEY: z.string().optional(),

  // OPENAI_API_KEY: z.string().optional(),

  // EMBEDDING_PROVIDER: z
  //   .string()
  //   .min(1, "EMBEDDING_PROVIDER is required"),

  // EMBEDDING_MODEL: z
  //   .string()
  //   .min(1, "EMBEDDING_MODEL is required"),
});

export const env = envSchema.parse(process.env);