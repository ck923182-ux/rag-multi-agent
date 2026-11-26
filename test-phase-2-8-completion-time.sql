
BEGIN;

INSERT INTO tenants (name, slug)
VALUES (
    'Phase 2.8 Completion Time Test',
    'phase-28-completion-time-test'
);

DO $$
DECLARE
    v_tenant UUID;
    v_rejected INTEGER := 0;
BEGIN
    SELECT id INTO v_tenant
    FROM tenants
    WHERE slug = 'phase-28-completion-time-test';

    -- LLM call: completion cannot precede start.
    BEGIN
        INSERT INTO llm_calls (
            tenant_id, provider, model, started_at, completed_at
        )
        VALUES (
            v_tenant,
            'test-provider',
            'test-model',
            '2026-01-02 12:00:00+00',
            '2026-01-02 11:59:59+00'
        );

        RAISE EXCEPTION 'FAIL: Invalid LLM completion time was accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Invalid LLM completion time rejected';
    END;

    -- Tool execution: completion cannot precede start.
    BEGIN
        INSERT INTO tool_executions (
            tenant_id, tool_name, started_at, completed_at
        )
        VALUES (
            v_tenant,
            'test-tool',
            '2026-01-02 12:00:00+00',
            '2026-01-02 11:59:59+00'
        );

        RAISE EXCEPTION 'FAIL: Invalid tool completion time was accepted';
    EXCEPTION WHEN check_violation THEN
        v_rejected := v_rejected + 1;
        RAISE NOTICE 'PASS: Invalid tool completion time rejected';
    END;

    IF v_rejected <> 2 THEN
        RAISE EXCEPTION 'FAIL: Expected 2 rejected cases; got %', v_rejected;
    END IF;
END;
$$;

ROLLBACK;
