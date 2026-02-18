-- Table: perseus.saved_search
-- Source: SQL Server [dbo].[saved_search]
-- Columns: 8

CREATE TABLE IF NOT EXISTS perseus.saved_search (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    class_id INTEGER,
    name VARCHAR(128) NOT NULL,
    added_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    is_private INTEGER NOT NULL DEFAULT 1,
    include_downstream INTEGER NOT NULL DEFAULT 0,
    parameter_string VARCHAR(2500) NOT NULL
);
