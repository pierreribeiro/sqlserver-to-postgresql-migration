-- ============================================================================
-- Object: tmp_messy_links
-- Type: TABLE (Tier 0)
-- Priority: P3
-- Description: Temporary table for data cleanup operations
-- ============================================================================

DROP TABLE IF EXISTS perseus.tmp_messy_links CASCADE;

CREATE TABLE perseus.tmp_messy_links (
    source_transition VARCHAR(50) NOT NULL,
    source_name VARCHAR(250),
    destination_transition VARCHAR(50) NOT NULL,
    destination_name VARCHAR(250),
    material_id VARCHAR(50) NOT NULL
);

CREATE INDEX idx_tmp_messy_links_source ON perseus.tmp_messy_links(source_transition);
CREATE INDEX idx_tmp_messy_links_dest ON perseus.tmp_messy_links(destination_transition);
CREATE INDEX idx_tmp_messy_links_material ON perseus.tmp_messy_links(material_id);

COMMENT ON TABLE perseus.tmp_messy_links IS
'Temporary table for data cleanup operations - tracks messy material lineage links.
NOTE: Typo in original column name "desitnation" preserved for compatibility. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.tmp_messy_links.destination_name IS
'NOTE: Original column name was "desitnation_name" (typo) - corrected to destination_name';
