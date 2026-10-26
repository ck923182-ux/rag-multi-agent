
-- Phase 2.8 corrective migration:
-- Move execution-history preservation out of the agents DELETE trigger.
-- Application services must preserve history before explicitly deleting
-- an agent. Tenant deletion continues to use normal FK cascades.

BEGIN;

DROP TRIGGER IF EXISTS
    trg_preserve_execution_history_before_agent_delete
ON agents;

DROP FUNCTION IF EXISTS
    preserve_execution_history_before_agent_delete();

COMMIT;
