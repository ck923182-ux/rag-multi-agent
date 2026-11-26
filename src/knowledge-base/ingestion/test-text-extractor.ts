import assert from "node:assert/strict";
import {
  extractText,
} from "./text-extractor.js";
import {
  TextExtractionError,
} from "./ingestion-types.js";

const plainTextResult = extractText({
  sourceType: "plain_text",
  content: "\uFEFFReturn policy\r\n\r\n\r\nYou can return an item within 30 days.   ",
});

assert.equal(
  plainTextResult.text,
  "Return policy\n\nYou can return an item within 30 days.",
);

const markdownResult = extractText({
  sourceType: "markdown",
  content: "# Return policy\r\n\r\n- Items can be returned within 30 days.",
});

assert.equal(
  markdownResult.text,
  "# Return policy\n\n- Items can be returned within 30 days.",
);

assert.throws(
  () =>
    extractText({
      sourceType: "plain_text",
      content: "   \r\n   ",
    }),
  (error: unknown) =>
    error instanceof TextExtractionError &&
    error.code === "EMPTY_CONTENT",
);

assert.throws(
  () =>
    extractText({
      sourceType: "html" as "plain_text",
      content: "<p>Hello</p>",
    }),
  (error: unknown) =>
    error instanceof TextExtractionError &&
    error.code === "UNSUPPORTED_SOURCE_TYPE",
);

console.log("Phase 3.3 text extraction tests passed.");