export type TextSourceType = "plain_text" | "markdown";

export interface TextExtractionInput {
  sourceType: TextSourceType;
  content: string;
  metadata?: Record<string, unknown>;
}

export interface TextExtractionResult {
  sourceType: TextSourceType;
  text: string;
  metadata?: Record<string, unknown>;
}

export type TextExtractionErrorCode =
  | "UNSUPPORTED_SOURCE_TYPE"
  | "INVALID_CONTENT"
  | "EMPTY_CONTENT";

export class TextExtractionError extends Error {
  constructor(
    public readonly code: TextExtractionErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "TextExtractionError";
  }
}