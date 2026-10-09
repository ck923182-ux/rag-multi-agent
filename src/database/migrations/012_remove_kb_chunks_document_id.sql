-- Chunks now belong to a specific document version.
-- Remove the obsolete direct document relationship.

ALTER TABLE kb_chunks
DROP COLUMN document_id;
