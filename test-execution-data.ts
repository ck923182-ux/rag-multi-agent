
import assert from "node:assert/strict";
import { sanitizeExecutionData } from "./src/shared/execution-data.js";

// Test 1: Sensitive fields are redacted.
const result = sanitizeExecutionData({
    provider: "test-provider",
    apiKey: "should-not-be-stored",
    nested: {
        access_token: "sensitive-value",
        message: "Request completed",
    },
});

assert.deepEqual(result, {
    provider: "test-provider",
    apiKey: "[REDACTED]",
    nested: {
        access_token: "[REDACTED]",
        message: "Request completed",
    },
});
console.log("PASS: Sensitive fields redacted");

// Test 2: Ordinary arrays and values are preserved.
assert.deepEqual(
    sanitizeExecutionData({ items: [1, "two", true, null] }),
    { items: [1, "two", true, null] },
);
console.log("PASS: Valid JSON data preserved");

// Test 3: Oversized payloads are rejected.
assert.throws(
    () => sanitizeExecutionData({ message: "x".repeat(1000) }, 100),
    /exceeds the 100-byte limit/,
);
console.log("PASS: Oversized payload rejected");

// Test 4: Excessive nesting is rejected.
let deeplyNested: unknown = "value";

for (let i = 0; i < 12; i++) {
    deeplyNested = { child: deeplyNested };
}

assert.throws(
    () => sanitizeExecutionData(deeplyNested),
    /maximum nesting depth/,
);
console.log("PASS: Excessive nesting rejected");

// Test 5: Unsupported JavaScript values are rejected.
assert.throws(
    () => sanitizeExecutionData({ count: Number.NaN }),
    /non-JSON value/,
);
console.log("PASS: Non-JSON values rejected");

console.log("All execution-data tests passed.");
