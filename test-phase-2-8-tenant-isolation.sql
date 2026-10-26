
BEGIN;

-- Create two isolated tenants.
INSERT INTO tenants (name, slug)
VALUES
    ('Phase 2.8 Isolation A', 'phase-28-isolation-a'),
    ('Phase 2.8 Isolation B', 'phase-28-isolation-b');

DO $$
DECLARE
    tenant_a UUID;
    tenant_b UUID;
    agent_a UUID;
    agent_b UUID;
    tool_b UUID;
    rejected_count INTEGER := 0;
BEGIN
    SELECT id INTO tenant_a
    FROM tenants WHERE slug = 'phase-28-isolation-a';

    SELECT id INTO tenant_b
    FROM tenants WHERE slug = 'phase-28-isolation-b';

    INSERT INTO agents (tenant_id, name, slug, agent_type)
    VALUES (tenant_a, 'Isolation Agent A', 'isolation-agent-a', 'test')
    RETURNING id INTO agent_a;

    INSERT INTO agents (tenant_id, name, slug, agent_type)
    VALUES (tenant_b, 'Isolation Agent B', 'isolation-agent-b', 'test')
    RETURNING id INTO agent_b;

    INSERT INTO tool_definitions (
        tenant_id, name, slug, tool_type, version, status
    )
    VALUES (
        tenant_b, 'Tenant B Tool', 'tenant-b-tool',
        'function', 1, 'draft'
    )
    RETURNING id INTO tool_b;

    -- Test 1: Tenant A cannot use Tenant B's agent in llm_calls.
    BEGIN
        INSERT INTO llm_calls (
            tenant_id, agent_id, provider, model
        )
        VALUES (
            tenant_a, agent_b, 'test-provider', 'test-model'
        );

        RAISE EXCEPTION 'FAIL: Cross-tenant llm_calls agent accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            rejected_count := rejected_count + 1;
            RAISE NOTICE 'PASS: Cross-tenant llm_calls agent rejected';
    END;

    -- Test 2: Tenant A cannot use Tenant B's agent in tool_executions.
    BEGIN
        INSERT INTO tool_executions (
            tenant_id, agent_id, tool_name
        )
        VALUES (
            tenant_a, agent_b, 'test-tool'
        );

        RAISE EXCEPTION 'FAIL: Cross-tenant tool_executions agent accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            rejected_count := rejected_count + 1;
            RAISE NOTICE 'PASS: Cross-tenant tool_executions agent rejected';
    END;

    -- Test 3: Tenant A cannot reference Tenant B's tool definition.
    BEGIN
        INSERT INTO tool_executions (
            tenant_id, tool_definition_id, tool_name, tool_version
        )
        VALUES (
            tenant_a, tool_b, 'tenant-b-tool', 1
        );

        RAISE EXCEPTION 'FAIL: Cross-tenant tool definition accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            rejected_count := rejected_count + 1;
            RAISE NOTICE 'PASS: Cross-tenant tool definition rejected';
    END;

    IF rejected_count <> 3 THEN
        RAISE EXCEPTION 'FAIL: Expected 3 rejected cases, got %',
            rejected_count;
    END IF;
END;
$$;

ROLLBACK;
