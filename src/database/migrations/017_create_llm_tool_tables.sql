
-- Phase 2.8: LLM usage and tool execution tables.
-- Enforces tenant-aware relationships and preserves execution history.

BEGIN;

-- 1. Tenant-owned, versioned tool definitions.
CREATE TABLE tool_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    tool_type VARCHAR(100) NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,

    description TEXT,
    input_schema JSONB NOT NULL DEFAULT '{}'::jsonb,
    config JSONB NOT NULL DEFAULT '{}'::jsonb,

    status VARCHAR(50) NOT NULL DEFAULT 'draft',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_tool_definitions_tenant
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_tool_definitions_tenant_slug_version
        UNIQUE (tenant_id, slug, version),

    CONSTRAINT chk_tool_definitions_version
        CHECK (version > 0),

    CONSTRAINT chk_tool_definitions_status
        CHECK (status IN ('draft', 'active', 'disabled'))
);

CREATE INDEX idx_tool_definitions_tenant_status
    ON tool_definitions(tenant_id, status);

CREATE INDEX idx_tool_definitions_tenant_slug
    ON tool_definitions(tenant_id, slug);

CREATE UNIQUE INDEX uq_tool_definitions_one_active_version
    ON tool_definitions(tenant_id, slug)
    WHERE status = 'active';

ALTER TABLE tool_definitions
    ADD CONSTRAINT uq_tool_definitions_id_tenant
    UNIQUE (id, tenant_id);


-- 2. One row per LLM provider API attempt.
CREATE TABLE llm_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    agent_id UUID,
    agent_run_id UUID,

    provider VARCHAR(100) NOT NULL,
    model VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',

    input_tokens BIGINT,
    output_tokens BIGINT,
    cached_input_tokens BIGINT,

    estimated_cost NUMERIC(18, 8),
    currency VARCHAR(3),

    latency_ms BIGINT,
    provider_request_id VARCHAR(255),

    error_code VARCHAR(100),
    error_message TEXT,

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_llm_calls_tenant
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_llm_calls_agent_tenant
        FOREIGN KEY (agent_id, tenant_id)
        REFERENCES agents(id, tenant_id)
        ON DELETE SET NULL (agent_id),

    CONSTRAINT fk_llm_calls_agent_run
        FOREIGN KEY (agent_run_id, agent_id)
        REFERENCES agent_runs(id, agent_id)
        ON DELETE SET NULL (agent_run_id),

    CONSTRAINT chk_llm_calls_status
        CHECK (
            status IN (
                'pending',
                'running',
                'succeeded',
                'failed',
                'cancelled'
            )
        ),

    CONSTRAINT chk_llm_calls_input_tokens
        CHECK (input_tokens IS NULL OR input_tokens >= 0),

    CONSTRAINT chk_llm_calls_output_tokens
        CHECK (output_tokens IS NULL OR output_tokens >= 0),

    CONSTRAINT chk_llm_calls_cached_tokens
        CHECK (cached_input_tokens IS NULL OR cached_input_tokens >= 0),

    CONSTRAINT chk_llm_calls_cost
        CHECK (estimated_cost IS NULL OR estimated_cost >= 0),

    CONSTRAINT chk_llm_calls_latency
        CHECK (latency_ms IS NULL OR latency_ms >= 0),

    CONSTRAINT chk_llm_calls_completion_time
        CHECK (
            completed_at IS NULL
            OR started_at IS NULL
            OR completed_at >= started_at
        )
);

CREATE INDEX idx_llm_calls_tenant_created
    ON llm_calls(tenant_id, created_at DESC);

CREATE INDEX idx_llm_calls_agent
    ON llm_calls(agent_id);

CREATE INDEX idx_llm_calls_agent_run
    ON llm_calls(agent_run_id);

CREATE INDEX idx_llm_calls_status
    ON llm_calls(status);

CREATE INDEX idx_llm_calls_provider_model
    ON llm_calls(provider, model);


-- 3. One row per tool invocation.
CREATE TABLE tool_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    agent_id UUID,
    agent_run_id UUID,
    tool_definition_id UUID,

    tool_name VARCHAR(255) NOT NULL,
    tool_version INTEGER,

    status VARCHAR(50) NOT NULL DEFAULT 'pending',

    arguments JSONB NOT NULL DEFAULT '{}'::jsonb,
    result_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    latency_ms BIGINT,
    error_code VARCHAR(100),
    error_message TEXT,

    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_tool_executions_tenant
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_tool_executions_agent_tenant
        FOREIGN KEY (agent_id, tenant_id)
        REFERENCES agents(id, tenant_id)
        ON DELETE SET NULL (agent_id),

    CONSTRAINT fk_tool_executions_agent_run
        FOREIGN KEY (agent_run_id, agent_id)
        REFERENCES agent_runs(id, agent_id)
        ON DELETE SET NULL (agent_run_id),

    CONSTRAINT fk_tool_executions_definition_tenant
        FOREIGN KEY (tool_definition_id, tenant_id)
        REFERENCES tool_definitions(id, tenant_id)
        ON DELETE SET NULL (tool_definition_id),

    CONSTRAINT chk_tool_executions_status
        CHECK (
            status IN (
                'pending',
                'running',
                'succeeded',
                'failed',
                'cancelled'
            )
        ),

    CONSTRAINT chk_tool_executions_version
        CHECK (tool_version IS NULL OR tool_version > 0),

    CONSTRAINT chk_tool_executions_latency
        CHECK (latency_ms IS NULL OR latency_ms >= 0),

    CONSTRAINT chk_tool_executions_completion_time
        CHECK (
            completed_at IS NULL
            OR started_at IS NULL
            OR completed_at >= started_at
        )
);

CREATE INDEX idx_tool_executions_tenant_created
    ON tool_executions(tenant_id, created_at DESC);

CREATE INDEX idx_tool_executions_agent
    ON tool_executions(agent_id);

CREATE INDEX idx_tool_executions_agent_run
    ON tool_executions(agent_run_id);

CREATE INDEX idx_tool_executions_definition
    ON tool_executions(tool_definition_id);

CREATE INDEX idx_tool_executions_status
    ON tool_executions(status);

COMMIT;
