import assert from "node:assert/strict";
import { chunkText } from "./text-chunker.js";

const shortText = "A short paragraph.";
const shortChunks = chunkText(shortText);

assert.equal(shortChunks.length, 1);
assert.equal(shortChunks[0]?.text, shortText);
assert.equal(shortChunks[0]?.chunkIndex, 0);
assert.ok((shortChunks[0]?.tokenCount ?? 0) > 0);

const longText = Array.from(
  { length: 1200 },
  (_, index) => `Sentence ${index + 1}.`,
).join(" ");

const chunks = chunkText(longText);

assert.ok(chunks.length > 1, "Long text should produce multiple chunks.");

for (const [index, chunk] of chunks.entries()) {
  assert.equal(chunk.chunkIndex, index);
  assert.ok(chunk.tokenCount > 0);
  assert.ok(
    chunk.tokenCount <= 500,
    `Chunk ${index} exceeds the 500-token limit.`,
  );
  assert.ok(chunk.text.length > 0);
}

const customChunks = chunkText(longText, {
  maxTokens: 100,
  overlapTokens: 20,
});

assert.ok(customChunks.length > 1);
assert.ok(customChunks.every((chunk) => chunk.tokenCount <= 100));

assert.deepEqual(chunkText(" \n\t "), []);

assert.throws(
  () => chunkText("Some text", { maxTokens: 0 }),
  /maxTokens must be a positive integer/,
);

assert.throws(
  () => chunkText("Some text", { maxTokens: 100, overlapTokens: 100 }),
  /overlapTokens must be a non-negative integer smaller than maxTokens/,
);

console.log("Phase 3.4 text chunker tests passed.");