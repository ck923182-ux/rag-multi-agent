
BEGIN;

INSERT INTO tenants (name, slug)
VALUES (
    'Phase 2.8 Execution Constraint Test',
    'phase-28-execution-constraints-test'
);

DO $$
DECLARE
    v_tenant UUID;
    v_agent UUID;
    v_rejected INTEGER := 0;
BEGIN
    SELECT id INTO v_tenant
    FROM tenants
    WHERE slug = 'phase-28-execution-constraints-test';

    INSERT INTO agents (tenant_id, name, slug, agent_type)
    VALUES (v_tenant, 'Constraint Test Agent', 'constraint-test-agent', 'test')
    RETURNING id INTO v_agent;

    -- LLM: negative input tokens must be rejected.
    BEGIN
        INSERT INTO llm_calls (tenant_id, provider, model, input_tokens)
        VALUES (v_tenant, 'test-provider', 'test-model', -1);
        RAISE EXCEPTION 'FAIL: Negative input tokens were accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Negative input tokens rejected';
    END;

    -- LLM: negative output tokens must be rejected.
    BEGIN
        INSERT INTO llm_calls (tenant_id, provider, model, output_tokens)
        VALUES (v_tenant, 'test-provider', 'test-model', -1);
        RAISE EXCEPTION 'FAIL: Negative output tokens were accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Negative output tokens rejected';
    END;

    -- LLM: negative cached tokens must be rejected.
    BEGIN
        INSERT INTO llm_calls (tenant_id, provider, model, cached_input_tokens)
        VALUES (v_tenant, 'test-provider', 'test-model', -1);
        RAISE EXCEPTION 'FAIL: Negative cached tokens were accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Negative cached tokens rejected';
    END;

    -- LLM: negative estimated cost must be rejected.
    BEGIN
        INSERT INTO llm_calls (tenant_id, provider, model, estimated_cost)
        VALUES (v_tenant, 'test-provider', 'test-model', -0.01);
        RAISE EXCEPTION 'FAIL: Negative estimated cost was accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Negative estimated cost rejected';
    END;

    -- LLM: negative latency must be rejected.
    BEGIN
        INSERT INTO llm_calls (tenant_id, provider, model, latency_ms)
        VALUES (v_tenant, 'test-provider', 'test-model', -1);
        RAISE EXCEPTION 'FAIL: Negative LLM latency was accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Negative LLM latency rejected';
    END;

    -- LLM: invalid status must be rejected.
    BEGIN
        INSERT INTO llm_calls (tenant_id, provider, model, status)
        VALUES (v_tenant, 'test-provider', 'test-model', 'processing');
        RAISE EXCEPTION 'FAIL: Invalid LLM status was accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Invalid LLM status rejected';
    END;

    -- Tool execution: invalid status must be rejected.
    BEGIN
        INSERT INTO tool_executions (tenant_id, tool_name, status)
        VALUES (v_tenant, 'test-tool', 'processing');
        RAISE EXCEPTION 'FAIL: Invalid tool status was accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Invalid tool status rejected';
    END;

    -- Tool execution: zero version must be rejected.
    BEGIN
        INSERT INTO tool_executions (tenant_id, tool_name, tool_version)
        VALUES (v_tenant, 'test-tool', 0);
        RAISE EXCEPTION 'FAIL: Tool version zero was accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Tool version zero rejected';
    END;

    -- Tool execution: negative latency must be rejected.
    BEGIN
        INSERT INTO tool_executions (tenant_id, tool_name, latency_ms)
        VALUES (v_tenant, 'test-tool', -1);
        RAISE EXCEPTION 'FAIL: Negative tool latency was accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Negative tool latency rejected';
    END;

    IF v_rejected <> 9 THEN
        RAISE EXCEPTION 'FAIL: Expected 9 rejected cases; got %', v_rejected;
    END IF;
END;
$$;

ROLLBACK;
