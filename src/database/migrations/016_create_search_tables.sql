
-- Phase 2.7: Search and observability tables.
-- Tenant ownership and cross-tenant references must be enforced.

BEGIN;

-- Required composite keys for tenant-safe foreign keys.
ALTER TABLE agents
    ADD CONSTRAINT uq_agents_id_tenant
    UNIQUE (id, tenant_id);

ALTER TABLE agent_runs
    ADD CONSTRAINT uq_agent_runs_id_agent
    UNIQUE (id, agent_id);

-- Record each search execution.
CREATE TABLE search_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id UUID NOT NULL,
    agent_id UUID,
    agent_run_id UUID,

    search_type VARCHAR(100) NOT NULL,
    query_text TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',

    input JSONB NOT NULL DEFAULT '{}'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    error_message TEXT,

    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_search_runs_tenant
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE,

    
    CONSTRAINT fk_search_runs_agent_tenant
        FOREIGN KEY (agent_id, tenant_id)
        REFERENCES agents(id, tenant_id)
        ON DELETE SET NULL (agent_id),


    CONSTRAINT fk_search_runs_agent_run
        FOREIGN KEY (agent_run_id, agent_id)
        REFERENCES agent_runs(id, agent_id)
        ON DELETE SET NULL (agent_run_id),

    CONSTRAINT chk_search_runs_status
        CHECK (
            status IN (
                'pending',
                'running',
                'completed',
                'failed',
                'cancelled'
            )
        ),

    
    CONSTRAINT chk_search_runs_completion_time
        CHECK (
            completed_at IS NULL
            OR started_at IS NULL
            OR completed_at >= started_at
        ),

    CONSTRAINT chk_search_runs_agent_run_requires_agent
        CHECK (
            agent_run_id IS NULL
            OR agent_id IS NOT NULL
        )
);


CREATE INDEX idx_search_runs_tenant_created
    ON search_runs(tenant_id, created_at DESC);

CREATE INDEX idx_search_runs_agent
    ON search_runs(agent_id);

CREATE INDEX idx_search_runs_agent_run
    ON search_runs(agent_run_id);

CREATE INDEX idx_search_runs_status
    ON search_runs(status);

CREATE INDEX idx_search_runs_type
    ON search_runs(search_type);

-- Store individual results returned by a search execution.
CREATE TABLE search_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    search_run_id UUID NOT NULL,

    result_type VARCHAR(100) NOT NULL,
    source_ref TEXT,
    rank INTEGER NOT NULL,

    score DOUBLE PRECISION,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_search_results_search_run
        FOREIGN KEY (search_run_id)
        REFERENCES search_runs(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_search_results_rank
        CHECK (rank > 0)
);

CREATE INDEX idx_search_results_search_run_rank
    ON search_results(search_run_id, rank);

CREATE INDEX idx_search_results_type
    ON search_results(result_type);

COMMIT;
