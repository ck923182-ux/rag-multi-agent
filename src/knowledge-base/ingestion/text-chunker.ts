import { getEncoding } from "js-tiktoken";

export interface ChunkingOptions {
  maxTokens?: number;
  overlapTokens?: number;
}

export interface TextChunk {
  chunkIndex: number;
  text: string;
  tokenCount: number;
}

const DEFAULT_MAX_TOKENS = 500;
const DEFAULT_OVERLAP_TOKENS = 60;

export function chunkText(
  text: string,
  options: ChunkingOptions = {},
): TextChunk[] {
  const maxTokens = options.maxTokens ?? DEFAULT_MAX_TOKENS;
  const overlapTokens = options.overlapTokens ?? DEFAULT_OVERLAP_TOKENS;

  if (!Number.isInteger(maxTokens) || maxTokens <= 0) {
    throw new Error("maxTokens must be a positive integer.");
  }

  if (
    !Number.isInteger(overlapTokens) ||
    overlapTokens < 0 ||
    overlapTokens >= maxTokens
  ) {
    throw new Error(
      "overlapTokens must be a non-negative integer smaller than maxTokens.",
    );
  }

  if (text.trim().length === 0) {
    return [];
  }

  const encoding = getEncoding("cl100k_base");
  const tokens = Array.from(encoding.encode(text));

  if (tokens.length === 0) {
    return [];
  }

  const chunks: TextChunk[] = [];
  let start = 0;

  while (start < tokens.length) {
    let end = Math.min(start + maxTokens, tokens.length);

    if (end < tokens.length) {
      // Prefer a natural boundary in the latter part of the chunk.
      const minimumPreferredEnd = start + Math.floor(maxTokens * 0.75);
      const candidateText = encoding.decode(
        Array.from(tokens.slice(start, end)),
      );

      const boundaryPattern = /(?:\n\n|\n|[.!?。！？])\s*/g;
      let preferredEnd: number | undefined;
      let match: RegExpExecArray | null;

      while ((match = boundaryPattern.exec(candidateText)) !== null) {
        const prefix = candidateText.slice(0, match.index + match[0].length);
        const prefixTokenCount = encoding.encode(prefix).length;

        if (
          start + prefixTokenCount >= minimumPreferredEnd &&
          start + prefixTokenCount <= end
        ) {
          preferredEnd = start + prefixTokenCount;
        }
      }

      if (preferredEnd !== undefined && preferredEnd - start > overlapTokens) {
        end = preferredEnd;
      }
    }

    const chunkTokens = tokens.slice(start, end);
    const chunkText = encoding.decode(Array.from(chunkTokens));

    if (chunkText.length > 0) {
      chunks.push({
        chunkIndex: chunks.length,
        text: chunkText,
        tokenCount: chunkTokens.length,
      });
    }

    if (end >= tokens.length) {
      break;
    }

    start = end - overlapTokens;
  }

  return chunks;
}
