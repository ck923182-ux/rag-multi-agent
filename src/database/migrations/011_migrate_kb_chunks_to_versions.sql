-- Associate each chunk with a specific document version.
-- Existing tables are currently empty, so no chunk backfill is needed.

ALTER TABLE kb_chunks
ADD COLUMN version_id UUID;

-- Replace the document-based unique constraint with version-based uniqueness.
ALTER TABLE kb_chunks
DROP CONSTRAINT uq_kb_chunks_document_index;

ALTER TABLE kb_chunks
DROP CONSTRAINT fk_kb_chunks_document;

-- Each chunk must belong to a valid document version.
ALTER TABLE kb_chunks
ADD CONSTRAINT fk_kb_chunks_version
FOREIGN KEY (version_id)
REFERENCES kb_document_versions(id)
ON DELETE CASCADE;

-- A chunk index must be unique within its version.
ALTER TABLE kb_chunks
ADD CONSTRAINT uq_kb_chunks_version_index
UNIQUE (version_id, chunk_index);

-- Existing chunks must always have a version association.
ALTER TABLE kb_chunks
ALTER COLUMN version_id SET NOT NULL;

-- Index the new version relationship for lookups and joins.
CREATE INDEX IF NOT EXISTS idx_kb_chunks_version_id
ON kb_chunks(version_id);

-- Remove the obsolete document-level index.
DROP INDEX IF EXISTS idx_kb_chunks_document_id;
