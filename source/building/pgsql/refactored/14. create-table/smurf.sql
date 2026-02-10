-- Table: perseus.smurf
-- Source: SQL Server [dbo].[smurf]
-- Columns: 6

CREATE TABLE IF NOT EXISTS perseus.smurf (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    class_id INTEGER NOT NULL,
    name VARCHAR(150) NOT NULL,
    description VARCHAR(500),
    themis_method_id INTEGER,
    disabled INTEGER NOT NULL DEFAULT 0
);
