
BEGIN;

INSERT INTO tenants (name, slug)
VALUES ('Phase 2.8 Tenant Cascade Test', 'phase-28-tenant-cascade-test');

DO $$
DECLARE
    test_tenant UUID;
    test_agent UUID;
    test_tool UUID;
BEGIN
    SELECT id INTO test_tenant
    FROM tenants
    WHERE slug = 'phase-28-tenant-cascade-test';

    INSERT INTO agents (tenant_id, name, slug, agent_type)
    VALUES (
        test_tenant,
        'Cascade Test Agent',
        'cascade-test-agent',
        'test'
    )
    RETURNING id INTO test_agent;

    INSERT INTO tool_definitions (
        tenant_id, name, slug, tool_type, version, status
    )
    VALUES (
        test_tenant,
        'Cascade Test Tool',
        'cascade-test-tool',
        'function',
        1,
        'draft'
    )
    RETURNING id INTO test_tool;

    INSERT INTO llm_calls (
        tenant_id, agent_id, provider, model
    )
    VALUES (
        test_tenant, test_agent, 'test-provider', 'test-model'
    );

    INSERT INTO tool_executions (
        tenant_id, agent_id, tool_definition_id, tool_name, tool_version
    )
    VALUES (
        test_tenant, test_agent, test_tool, 'Cascade Test Tool', 1
    );

    DELETE FROM tenants
    WHERE id = test_tenant;

    IF EXISTS (
        SELECT 1 FROM tool_definitions WHERE tenant_id = test_tenant
    ) THEN
        RAISE EXCEPTION 'FAIL: Tool definitions remain after tenant deletion';
    END IF;

    IF EXISTS (
        SELECT 1 FROM llm_calls WHERE tenant_id = test_tenant
    ) THEN
        RAISE EXCEPTION 'FAIL: LLM calls remain after tenant deletion';
    END IF;

    IF EXISTS (
        SELECT 1 FROM tool_executions WHERE tenant_id = test_tenant
    ) THEN
        RAISE EXCEPTION 'FAIL: Tool executions remain after tenant deletion';
    END IF;

    RAISE NOTICE
        'PASS: Tenant deletion cascaded to tool definitions, LLM calls, and tool executions';
END;
$$;

ROLLBACK;
