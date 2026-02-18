-- Table: perseus.material_qc
-- Source: SQL Server [dbo].[material_qc]
-- Columns: 5

CREATE TABLE IF NOT EXISTS perseus.material_qc (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    material_id INTEGER NOT NULL,
    entity_type_name TEXT NOT NULL,
    foreign_entity_id INTEGER NOT NULL,
    qc_process_uid TEXT NOT NULL
);
