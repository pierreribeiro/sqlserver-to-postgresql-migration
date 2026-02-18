-- Table: perseus.fatsmurf_history
-- Source: SQL Server [dbo].[fatsmurf_history]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.fatsmurf_history (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    fatsmurf_id INTEGER NOT NULL
);
