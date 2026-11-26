
-- Store versioned configurations for each agent.

CREATE TABLE IF NOT EXISTS agent_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL,
    config_version INTEGER NOT NULL DEFAULT 1,
    config JSONB NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_agent_configs_agent
        FOREIGN KEY (agent_id)
        REFERENCES agents(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_agent_configs_agent_version
        UNIQUE (agent_id, config_version),

    CONSTRAINT chk_agent_configs_version
        CHECK (config_version > 0)
);

CREATE INDEX IF NOT EXISTS idx_agent_configs_agent_id
    ON agent_configs(agent_id);

CREATE INDEX IF NOT EXISTS idx_agent_configs_active
    ON agent_configs(agent_id, is_active);
