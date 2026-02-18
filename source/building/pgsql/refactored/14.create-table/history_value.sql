-- Table: perseus.history_value
-- Source: SQL Server [dbo].[history_value]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.history_value (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    value VARCHAR(250)
);
