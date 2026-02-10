-- Table: perseus.tmp_messy_links
-- Source: SQL Server [dbo].[tmp_messy_links]
-- Columns: 5

CREATE TABLE IF NOT EXISTS perseus.tmp_messy_links (
    source_transition VARCHAR(50) NOT NULL,
    source_name VARCHAR(150),
    destination_transition VARCHAR(50) NOT NULL,
    desitnation_name VARCHAR(150),
    material_id VARCHAR(50) NOT NULL
);
