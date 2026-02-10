-- Table: perseus.coa_spec
-- Source: SQL Server [dbo].[coa_spec]
-- Columns: 9

CREATE TABLE IF NOT EXISTS perseus.coa_spec (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    coa_id INTEGER NOT NULL,
    property_id INTEGER NOT NULL,
    upper_bound DOUBLE PRECISION,
    lower_bound DOUBLE PRECISION,
    equal_bound VARCHAR(150),
    upper_equal_bound DOUBLE PRECISION,
    lower_equal_bound DOUBLE PRECISION,
    result_precision INTEGER DEFAULT 0
);
