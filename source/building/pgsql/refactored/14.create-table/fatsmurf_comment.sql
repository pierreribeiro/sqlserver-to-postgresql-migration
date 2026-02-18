-- Table: perseus.fatsmurf_comment
-- Source: SQL Server [dbo].[fatsmurf_comment]
-- Columns: 5

CREATE TABLE IF NOT EXISTS perseus.fatsmurf_comment (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    fatsmurf_id INTEGER NOT NULL,
    added_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    comment TEXT NOT NULL
);
