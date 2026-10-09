
CREATE TABLE IF NOT EXISTS kb_document_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  document_id UUID NOT NULL,

  version_number INTEGER NOT NULL,

  content_hash VARCHAR(64) NOT NULL,

  status VARCHAR(50) NOT NULL DEFAULT 'pending',

  error_message TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_kb_document_versions_document
    FOREIGN KEY (document_id)
    REFERENCES kb_documents(id)
    ON DELETE CASCADE,

  CONSTRAINT uq_kb_document_versions_number
    UNIQUE (document_id, version_number),

  CONSTRAINT chk_kb_document_versions_number
    CHECK (version_number > 0)
);

CREATE INDEX IF NOT EXISTS idx_kb_document_versions_document_id
ON kb_document_versions(document_id);

CREATE INDEX IF NOT EXISTS idx_kb_document_versions_status
ON kb_document_versions(status);