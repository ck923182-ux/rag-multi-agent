
BEGIN;

INSERT INTO tenants (name, slug)
VALUES ('Phase 2.8 Tool Deletion Test', 'phase-28-tool-delete-test');

DO $$
DECLARE
    test_tenant UUID;
    test_tool UUID;
    test_execution UUID;
    saved_tool_name TEXT;
    saved_tool_version INTEGER;
BEGIN
    SELECT id INTO test_tenant
    FROM tenants
    WHERE slug = 'phase-28-tool-delete-test';

    INSERT INTO tool_definitions (
        tenant_id, name, slug, tool_type, version, status
    )
    VALUES (
        test_tenant,
        'Historical Test Tool',
        'historical-test-tool',
        'function',
        3,
        'disabled'
    )
    RETURNING id INTO test_tool;

    INSERT INTO tool_executions (
        tenant_id,
        tool_definition_id,
        tool_name,
        tool_version,
        status
    )
    VALUES (
        test_tenant,
        test_tool,
        'Historical Test Tool',
        3,
        'succeeded'
    )
    RETURNING id INTO test_execution;

    DELETE FROM tool_definitions
    WHERE id = test_tool;

    SELECT tool_name, tool_version
    INTO saved_tool_name, saved_tool_version
    FROM tool_executions
    WHERE id = test_execution
      AND tool_definition_id IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'FAIL: Execution history was deleted or tool reference was not cleared';
    END IF;

    IF saved_tool_name <> 'Historical Test Tool'
       OR saved_tool_version <> 3 THEN
        RAISE EXCEPTION 'FAIL: Historical tool name/version was not preserved';
    END IF;

    RAISE NOTICE
        'PASS: Execution history preserved; tool reference cleared; name and version retained';
END;
$$;

ROLLBACK;
