-- Table: perseus.submission_entry
-- Source: SQL Server [dbo].[submission_entry]
-- Columns: 9

CREATE TABLE IF NOT EXISTS perseus.submission_entry (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    assay_type_id INTEGER NOT NULL,
    material_id INTEGER NOT NULL,
    status VARCHAR(19) NOT NULL,
    priority VARCHAR(6) NOT NULL,
    submission_id INTEGER NOT NULL,
    prepped_by_id INTEGER,
    themis_tray_id INTEGER,
    sample_type VARCHAR(7) NOT NULL
);
