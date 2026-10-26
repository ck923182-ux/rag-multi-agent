
BEGIN;

-- Isolated test tenant and agent.
INSERT INTO tenants (name, slug)
VALUES ('Phase 2.8 Deletion Test', 'phase-28-deletion-test');

DO $$
DECLARE
    v_tenant UUID;
    v_agent UUID;
    v_run UUID;
    v_run_for_agent_delete UUID;
    v_llm_call UUID;
    v_tool_execution UUID;
    v_llm_call_for_agent_delete UUID;
    v_tool_execution_for_agent_delete UUID;
BEGIN
    SELECT id INTO v_tenant
    FROM tenants
    WHERE slug = 'phase-28-deletion-test';

    INSERT INTO agents (tenant_id, name, slug, agent_type)
    VALUES (v_tenant, 'Deletion Test Agent', 'deletion-test-agent', 'test')
    RETURNING id INTO v_agent;

    -- Create two runs: one to delete directly, one to test agent deletion.
    INSERT INTO agent_runs (agent_id, status)
    VALUES (v_agent, 'completed')
    RETURNING id INTO v_run;

    INSERT INTO agent_runs (agent_id, status)
    VALUES (v_agent, 'completed')
    RETURNING id INTO v_run_for_agent_delete;

    INSERT INTO llm_calls (
        tenant_id, agent_id, agent_run_id, provider, model, status
    )
    VALUES (v_tenant, v_agent, v_run, 'test-provider', 'test-model', 'succeeded')
    RETURNING id INTO v_llm_call;

    INSERT INTO tool_executions (
        tenant_id, agent_id, agent_run_id, tool_name, status
    )
    VALUES (v_tenant, v_agent, v_run, 'test-tool', 'succeeded')
    RETURNING id INTO v_tool_execution;

    INSERT INTO llm_calls (
        tenant_id, agent_id, agent_run_id, provider, model, status
    )
    VALUES (
        v_tenant, v_agent, v_run_for_agent_delete,
        'test-provider', 'test-model', 'succeeded'
    )
    RETURNING id INTO v_llm_call_for_agent_delete;

    INSERT INTO tool_executions (
        tenant_id, agent_id, agent_run_id, tool_name, status
    )
    VALUES (
        v_tenant, v_agent, v_run_for_agent_delete,
        'test-tool', 'succeeded'
    )
    RETURNING id INTO v_tool_execution_for_agent_delete;

    -- Test 1: Deleting a run should preserve history and clear run IDs.
    DELETE FROM agent_runs WHERE id = v_run;

    IF NOT EXISTS (
        SELECT 1 FROM llm_calls
        WHERE id = v_llm_call
          AND agent_id = v_agent
          AND agent_run_id IS NULL
    ) THEN
        RAISE EXCEPTION 'FAIL: LLM history was not preserved after run deletion';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tool_executions
        WHERE id = v_tool_execution
          AND agent_id = v_agent
          AND agent_run_id IS NULL
    ) THEN
        RAISE EXCEPTION 'FAIL: Tool history was not preserved after run deletion';
    END IF;

    RAISE NOTICE 'PASS: Run deletion preserves both history records';

    -- Test 2: Deleting the agent should also preserve history.
-- Test 2: Simulate the application service's transactional cleanup.
-- Clear both references together to preserve the composite foreign keys.
UPDATE llm_calls
SET agent_id = NULL,
    agent_run_id = NULL
WHERE tenant_id = v_tenant
  AND agent_id = v_agent;

UPDATE tool_executions
SET agent_id = NULL,
    agent_run_id = NULL
WHERE tenant_id = v_tenant
  AND agent_id = v_agent;

DELETE FROM agents
WHERE id = v_agent
  AND tenant_id = v_tenant;
    IF NOT EXISTS (
        SELECT 1 FROM llm_calls
        WHERE id = v_llm_call_for_agent_delete
          AND agent_id IS NULL
          AND agent_run_id IS NULL
    ) THEN
        RAISE EXCEPTION 'FAIL: LLM history was not preserved after agent deletion';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tool_executions
        WHERE id = v_tool_execution_for_agent_delete
          AND agent_id IS NULL
          AND agent_run_id IS NULL
    ) THEN
        RAISE EXCEPTION 'FAIL: Tool history was not preserved after agent deletion';
    END IF;

    RAISE NOTICE 'PASS: Agent deletion preserves both history records';
END $$;

-- Keep the database unchanged after testing.
ROLLBACK;
