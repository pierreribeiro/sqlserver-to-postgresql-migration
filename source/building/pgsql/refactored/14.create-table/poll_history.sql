-- Table: perseus.poll_history
-- Source: SQL Server [dbo].[poll_history]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.poll_history (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    poll_id INTEGER NOT NULL
);
