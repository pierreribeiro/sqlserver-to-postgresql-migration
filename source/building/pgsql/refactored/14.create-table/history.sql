-- Table: perseus.history
-- Source: SQL Server [dbo].[history]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.history (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    history_type_id INTEGER NOT NULL,
    creator_id INTEGER NOT NULL,
    created_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
