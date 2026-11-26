-- Track the latest successfully ingested version of each KB document.
-- NULL means no successful version has been selected yet.

ALTER TABLE kb_documents
ADD COLUMN IF NOT EXISTS current_version_id UUID;

-- A composite foreign key requires a matching unique constraint.
-- The version ID is already a primary key, but the pair also verifies
-- that the version belongs to the referenced document.
ALTER TABLE kb_document_versions
ADD CONSTRAINT uq_kb_document_versions_document_id_id
UNIQUE (document_id, id);

-- Ensure the selected version belongs to this exact document.
ALTER TABLE kb_documents
ADD CONSTRAINT fk_kb_documents_current_version
FOREIGN KEY (id, current_version_id)
REFERENCES kb_document_versions (document_id, id)
ON DELETE SET NULL (current_version_id);
