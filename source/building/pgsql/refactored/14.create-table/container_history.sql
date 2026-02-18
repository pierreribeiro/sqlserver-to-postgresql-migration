-- Table: perseus.container_history
-- Source: SQL Server [dbo].[container_history]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.container_history (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    container_id INTEGER NOT NULL
);
