CREATE TABLE IF NOT EXISTS kb_chunks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  document_id UUID NOT NULL,

  chunk_index INTEGER NOT NULL,

  content TEXT NOT NULL,

  content_hash VARCHAR(64),

  token_count INTEGER,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_kb_chunks_document
    FOREIGN KEY (document_id)
    REFERENCES kb_documents(id)
    ON DELETE CASCADE,

  CONSTRAINT uq_kb_chunks_document_index
    UNIQUE (document_id, chunk_index),

  CONSTRAINT chk_kb_chunks_chunk_index
    CHECK (chunk_index >= 0),

  CONSTRAINT chk_kb_chunks_token_count
    CHECK (token_count IS NULL OR token_count >= 0)
);

CREATE INDEX IF NOT EXISTS idx_kb_chunks_document_id
ON kb_chunks(document_id);

CREATE INDEX IF NOT EXISTS idx_kb_chunks_content_hash
ON kb_chunks(content_hash);