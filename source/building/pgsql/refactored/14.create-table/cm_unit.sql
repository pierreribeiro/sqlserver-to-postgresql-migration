-- Table: perseus.cm_unit
-- Source: SQL Server [dbo].[cm_unit]
-- Columns: 7

CREATE TABLE IF NOT EXISTS perseus.cm_unit (
    id INTEGER NOT NULL,
    description VARCHAR(150),
    longname VARCHAR(50),
    dimensions_id INTEGER,
    name VARCHAR(25),
    factor NUMERIC(20,10),
    "offset" NUMERIC(20,10)
);
