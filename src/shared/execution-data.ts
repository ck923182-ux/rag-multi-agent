
const DEFAULT_MAX_BYTES = 16 * 1024;
const MAX_DEPTH = 10;

const SENSITIVE_KEY_PATTERN =
    /password|passwd|secret|token|authorization|api[_-]?key|access[_-]?key|cookie|credential/i;

function redactRecursively(
    value: unknown,
    depth: number,
): unknown {
    if (depth > MAX_DEPTH) {
        throw new RangeError(
            `Execution metadata exceeds maximum nesting depth (${MAX_DEPTH})`,
        );
    }

    if (Array.isArray(value)) {
        return value.map((item) => redactRecursively(item, depth + 1));
    }

    if (value !== null && typeof value === "object") {
        const output: Record<string, unknown> = {};

        for (const [key, item] of Object.entries(value)) {
            output[key] = SENSITIVE_KEY_PATTERN.test(key)
                ? "[REDACTED]"
                : redactRecursively(item, depth + 1);
        }

        return output;
    }

    if (
        value === null ||
        typeof value === "string" ||
        typeof value === "boolean" ||
        (typeof value === "number" && Number.isFinite(value))
    ) {
        return value;
    }

    // Do not silently serialize unsupported values such as functions,
    // bigint, undefined, or non-finite numbers.
    throw new TypeError("Execution metadata contains a non-JSON value");
}

export function sanitizeExecutionData(
    value: unknown,
    maxBytes = DEFAULT_MAX_BYTES,
): unknown {
    if (!Number.isSafeInteger(maxBytes) || maxBytes <= 0) {
        throw new RangeError("maxBytes must be a positive safe integer");
    }

    const sanitized = redactRecursively(value, 0);
    const serialized = JSON.stringify(sanitized);

    if (Buffer.byteLength(serialized, "utf8") > maxBytes) {
        throw new RangeError(
            `Sanitized execution metadata exceeds the ${maxBytes}-byte limit`,
        );
    }

    return sanitized;
}
