-- Table: perseus.smurf_group_member
-- Source: SQL Server [dbo].[smurf_group_member]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.smurf_group_member (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    smurf_group_id INTEGER NOT NULL,
    smurf_id INTEGER NOT NULL
);
