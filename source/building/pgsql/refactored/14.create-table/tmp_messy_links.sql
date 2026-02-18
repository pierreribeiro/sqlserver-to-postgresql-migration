-- Table: perseus.tmp_messy_links
-- Source: SQL Server [dbo].[tmp_messy_links]
-- Columns: 5
-- UTILITY TABLE: data cleanup only, not production schema

CREATE TABLE IF NOT EXISTS perseus.tmp_messy_links (
    source_transition VARCHAR(50) NOT NULL,
    source_name VARCHAR(150),
    destination_transition VARCHAR(50) NOT NULL,
    destination_name VARCHAR(150),
    material_id VARCHAR(50) NOT NULL
);
