-- Table: perseus.goo_history
-- Source: SQL Server [dbo].[goo_history]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.goo_history (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    goo_id INTEGER NOT NULL
);
