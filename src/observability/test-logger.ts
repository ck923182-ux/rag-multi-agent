import { logger } from "./logger.js";

logger.info("Application started");

logger.info("Agent execution started", {
  agent: "customer-support",
  tenantId: "tenant-123",
});

logger.warn("Search returned low confidence", {
  score: 0.42,
});

logger.error("Example error log", {
  code: "TEST_ERROR",
});