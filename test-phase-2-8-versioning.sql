
BEGIN;

-- Version 1: active
INSERT INTO tool_definitions (
    tenant_id, name, slug, tool_type, version, status
)
VALUES (
    '6d363ef6-82ee-42eb-b19d-3c81c2d9fa59',
    'Phase 2.8 Version Test',
    'phase-28-version-test',
    'function',
    1,
    'active'
);

-- Version 2: draft (should succeed)
INSERT INTO tool_definitions (
    tenant_id, name, slug, tool_type, version, status
)
VALUES (
    '6d363ef6-82ee-42eb-b19d-3c81c2d9fa59',
    'Phase 2.8 Version Test',
    'phase-28-version-test',
    'function',
    2,
    'draft'
);

-- Attempt to activate version 2.
-- Expected: unique_violation because version 1 is active.
DO $$
BEGIN
    BEGIN
        UPDATE tool_definitions
        SET status = 'active'
        WHERE tenant_id = '6d363ef6-82ee-42eb-b19d-3c81c2d9fa59'
          AND slug = 'phase-28-version-test'
          AND version = 2;

        RAISE EXCEPTION 'FAIL: A second active version was allowed';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'PASS: A second active version was rejected';
    END;
END;
$$;

-- Verify the final states before rollback.
SELECT slug, version, status
FROM tool_definitions
WHERE tenant_id = '6d363ef6-82ee-42eb-b19d-3c81c2d9fa59'
  AND slug = 'phase-28-version-test'
ORDER BY version;

ROLLBACK;
