import {
  TextExtractionError,
  type TextExtractionInput,
  type TextExtractionResult,
} from "./ingestion-types.js";
import { normalizeText } from "./text-normalizer.js";

export function extractText(
  input: TextExtractionInput,
): TextExtractionResult {
  if (typeof input.content !== "string") {
    throw new TextExtractionError(
      "INVALID_CONTENT",
      "Text content must be a string.",
    );
  }

  switch (input.sourceType) {
    case "plain_text":
    case "markdown": {
      const result: TextExtractionResult = {
        sourceType: input.sourceType,
        text: normalizeText(input.content),
        ...(input.metadata === undefined
          ? {}
          : { metadata: input.metadata }),
      };

      return result;
    }

    default:
      throw new TextExtractionError(
        "UNSUPPORTED_SOURCE_TYPE",
        `Unsupported source type: ${String(input.sourceType)}`,
      );
  }
}