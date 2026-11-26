import { TextExtractionError } from "./ingestion-types.js";

export function normalizeText(input: string): string {
  if (typeof input !== "string") {
    throw new TextExtractionError(
      "INVALID_CONTENT",
      "Text content must be a string.",
    );
  }

  const normalized = input
    .replace(/^\uFEFF/, "") // Remove a leading byte-order mark.
    .replace(/\r\n?/g, "\n") // Standardize line endings.
    .replace(/[ \t]+$/gm, "") // Remove trailing spaces from each line.
    .replace(/\n{3,}/g, "\n\n") // Limit consecutive blank lines.
    .trim();

  if (normalized.length === 0) {
    throw new TextExtractionError(
      "EMPTY_CONTENT",
      "The source contains no usable text after normalization.",
    );
  }

  return normalized;
}