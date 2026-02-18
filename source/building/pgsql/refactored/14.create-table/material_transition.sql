-- Table: perseus.material_transition
-- Source: SQL Server [dbo].[material_transition]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.material_transition (
    material_id VARCHAR(50) NOT NULL,
    transition_id VARCHAR(50) NOT NULL,
    added_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
