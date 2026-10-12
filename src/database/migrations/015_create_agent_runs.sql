
-- Store execution records for agent runs.

CREATE TABLE IF NOT EXISTS agent_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL,
    config_id UUID,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    input JSONB NOT NULL DEFAULT '{}'::jsonb,
    output JSONB,
    error_message TEXT,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_agent_runs_agent
        FOREIGN KEY (agent_id)
        REFERENCES agents(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_agent_runs_config
        FOREIGN KEY (config_id)
        REFERENCES agent_configs(id)
        ON DELETE SET NULL,

    CONSTRAINT chk_agent_runs_status
        CHECK (
            status IN (
                'pending',
                'running',
                'completed',
                'failed',
                'cancelled'
            )
        ),

    CONSTRAINT chk_agent_runs_completion_time
        CHECK (
            completed_at IS NULL
            OR started_at IS NULL
            OR completed_at >= started_at
        )
);

CREATE INDEX IF NOT EXISTS idx_agent_runs_agent_id
    ON agent_runs(agent_id);

CREATE INDEX IF NOT EXISTS idx_agent_runs_config_id
    ON agent_runs(config_id);

CREATE INDEX IF NOT EXISTS idx_agent_runs_status
    ON agent_runs(status);

CREATE INDEX IF NOT EXISTS idx_agent_runs_created_at
    ON agent_runs(created_at);