
BEGIN;

INSERT INTO tool_definitions (
    tenant_id, name, slug, tool_type, version, status
)
VALUES (
    '6d363ef6-82ee-42eb-b19d-3c81c2d9fa59',
    'Phase 2.8 Constraint Test',
    'phase-28-constraint-test',
    'function',
    1,
    'draft'
);

DO $$
DECLARE
    rejected_count INTEGER := 0;
BEGIN
    -- Test 1: duplicate version
    BEGIN
        INSERT INTO tool_definitions (
            tenant_id, name, slug, tool_type, version, status
        )
        VALUES (
            '6d363ef6-82ee-42eb-b19d-3c81c2d9fa59',
            'Phase 2.8 Constraint Test',
            'phase-28-constraint-test',
            'function',
            1,
            'draft'
        );

        RAISE EXCEPTION 'FAIL: Duplicate version was accepted';
    EXCEPTION
        WHEN unique_violation THEN
            rejected_count := rejected_count + 1;
            RAISE NOTICE 'PASS: Duplicate version rejected';
    END;

    -- Test 2: invalid status
    BEGIN
        INSERT INTO tool_definitions (
            tenant_id, name, slug, tool_type, version, status
        )
        VALUES (
            '6d363ef6-82ee-42eb-b19d-3c81c2d9fa59',
            'Phase 2.8 Constraint Test',
            'phase-28-invalid-status',
            'function',
            1,
            'running'
        );

        RAISE EXCEPTION 'FAIL: Invalid status was accepted';
    EXCEPTION
        WHEN check_violation THEN
            rejected_count := rejected_count + 1;
            RAISE NOTICE 'PASS: Invalid status rejected';
    END;

    -- Test 3: version must be greater than zero
    BEGIN
        INSERT INTO tool_definitions (
            tenant_id, name, slug, tool_type, version, status
        )
        VALUES (
            '6d363ef6-82ee-42eb-b19d-3c81c2d9fa59',
            'Phase 2.8 Constraint Test',
            'phase-28-invalid-version',
            'function',
            0,
            'draft'
        );

        RAISE EXCEPTION 'FAIL: Version zero was accepted';
    EXCEPTION
        WHEN check_violation THEN
            rejected_count := rejected_count + 1;
            RAISE NOTICE 'PASS: Version zero rejected';
    END;

    IF rejected_count <> 3 THEN
        RAISE EXCEPTION 'FAIL: Expected 3 rejected cases, got %',
            rejected_count;
    END IF;
END;
$$;

ROLLBACK;
