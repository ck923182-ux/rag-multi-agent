CREATE TABLE IF NOT EXISTS kb_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id UUID NOT NULL,

  title VARCHAR(500) NOT NULL,

  source_type VARCHAR(50) NOT NULL,

  source_url TEXT,

  external_id VARCHAR(255),

  status VARCHAR(50) NOT NULL DEFAULT 'active',

  content_hash VARCHAR(64),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_kb_documents_tenant
    FOREIGN KEY (tenant_id)
    REFERENCES tenants(id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_kb_documents_tenant_id
ON kb_documents(tenant_id);

CREATE INDEX IF NOT EXISTS idx_kb_documents_source_type
ON kb_documents(source_type);

CREATE INDEX IF NOT EXISTS idx_kb_documents_external_id
ON kb_documents(external_id);

CREATE INDEX IF NOT EXISTS idx_kb_documents_content_hash
ON kb_documents(content_hash);