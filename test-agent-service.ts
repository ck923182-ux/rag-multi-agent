
import assert from "node:assert/strict";
import { pool } from "./src/database/postgres.js";
import { deleteAgent } from "./src/agents/agent.service.js";

const tenantSlug = `agent-service-test-${crypto.randomUUID()}`;

let tenantId: string | undefined;
let agentId: string | undefined;
let llmCallId: string | undefined;
let toolExecutionId: string | undefined;

try {
    const tenantResult = await pool.query(
        `INSERT INTO tenants (name, slug)
         VALUES ($1, $2)
         RETURNING id`,
        ["Agent Service Integration Test", tenantSlug],
    );
    tenantId = tenantResult.rows[0].id;

    const agentResult = await pool.query(
        `INSERT INTO agents (tenant_id, name, slug, agent_type)
         VALUES ($1, $2, $3, $4)
         RETURNING id`,
        [tenantId, "Service Test Agent", "service-test-agent", "test"],
    );
    agentId = agentResult.rows[0].id;

    const runResult = await pool.query(
        `INSERT INTO agent_runs (agent_id, status)
         VALUES ($1, $2)
         RETURNING id`,
        [agentId, "completed"],
    );
    const runId: string = runResult.rows[0].id;

    const llmResult = await pool.query(
        `INSERT INTO llm_calls
            (tenant_id, agent_id, agent_run_id, provider, model, status)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id`,
        [tenantId, agentId, runId, "test-provider", "test-model", "succeeded"],
    );
    llmCallId = llmResult.rows[0].id;

    const toolResult = await pool.query(
        `INSERT INTO tool_executions
            (tenant_id, agent_id, agent_run_id, tool_name, status)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id`,
        [tenantId, agentId, runId, "test-tool", "succeeded"],
    );
    toolExecutionId = toolResult.rows[0].id;

    const deleted = await deleteAgent(tenantId, agentId);
    assert.equal(deleted, true, "Expected the agent to be deleted");

    const llmCheck = await pool.query(
        `SELECT tenant_id, agent_id, agent_run_id
         FROM llm_calls WHERE id = $1`,
        [llmCallId],
    );
    assert.equal(llmCheck.rowCount, 1, "LLM history should remain");
    assert.equal(llmCheck.rows[0].tenant_id, tenantId);
    assert.equal(llmCheck.rows[0].agent_id, null);
    assert.equal(llmCheck.rows[0].agent_run_id, null);

    const toolCheck = await pool.query(
        `SELECT tenant_id, agent_id, agent_run_id
         FROM tool_executions WHERE id = $1`,
        [toolExecutionId],
    );
    assert.equal(toolCheck.rowCount, 1, "Tool history should remain");
    assert.equal(toolCheck.rows[0].tenant_id, tenantId);
    assert.equal(toolCheck.rows[0].agent_id, null);
    assert.equal(toolCheck.rows[0].agent_run_id, null);

    console.log("PASS: deleteAgent preserves LLM and tool history");
    console.log("PASS: execution history has no agent/run references");
} catch (error) {
    console.error("FAIL: Agent service integration test", error);
    process.exitCode = 1;
} finally {
    // Remove only the temporary test tenant and any remaining test data.
    if (tenantId) {
        try {
            await pool.query("DELETE FROM tenants WHERE id = $1", [tenantId]);
        } catch (cleanupError) {
            console.error("Test cleanup failed:", cleanupError);
            process.exitCode = 1;
        }
    }
    await pool.end();
}
