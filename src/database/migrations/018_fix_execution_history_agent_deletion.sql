
-- Phase 2.8 corrective migration:
-- Preserve LLM and tool execution history when an agent is deleted.
-- Clear both optional references before agent_runs cascade deletion.

BEGIN;

CREATE OR REPLACE FUNCTION preserve_execution_history_before_agent_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE llm_calls
    SET agent_id = NULL,
        agent_run_id = NULL
    WHERE agent_id = OLD.id;

    UPDATE tool_executions
    SET agent_id = NULL,
        agent_run_id = NULL
    WHERE agent_id = OLD.id;

    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_preserve_execution_history_before_agent_delete
BEFORE DELETE ON agents
FOR EACH ROW
EXECUTE FUNCTION preserve_execution_history_before_agent_delete();

COMMIT;
