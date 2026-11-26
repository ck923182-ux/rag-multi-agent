
import { pool } from "../database/postgres.js";

export async function deleteAgent(
    tenantId: string,
    agentId: string,
): Promise<boolean> {
    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        // Confirm that this agent belongs to the requesting tenant.
        const agentResult = await client.query(
            `SELECT id
             FROM agents
             WHERE id = $1 AND tenant_id = $2
             FOR UPDATE`,
            [agentId, tenantId],
        );

        if (agentResult.rowCount === 0) {
            await client.query("ROLLBACK");
            return false;
        }

        // Preserve history while removing references to this agent/run.
        await client.query(
            `UPDATE llm_calls
             SET agent_id = NULL,
                 agent_run_id = NULL
             WHERE tenant_id = $1 AND agent_id = $2`,
            [tenantId, agentId],
        );

        await client.query(
            `UPDATE tool_executions
             SET agent_id = NULL,
                 agent_run_id = NULL
             WHERE tenant_id = $1 AND agent_id = $2`,
            [tenantId, agentId],
        );

        // The transaction is tenant-scoped and history has been preserved.
        const deleteResult = await client.query(
            `DELETE FROM agents
             WHERE id = $1 AND tenant_id = $2`,
            [agentId, tenantId],
        );

        await client.query("COMMIT");

        return deleteResult.rowCount === 1;
    } catch (error) {
        await client.query("ROLLBACK");
        throw error;
    } finally {
        client.release();
    }
}
