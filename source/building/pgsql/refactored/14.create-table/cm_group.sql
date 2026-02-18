-- Table: perseus.cm_group
-- Source: SQL Server [dbo].[cm_group]
-- Columns: 5

CREATE TABLE IF NOT EXISTS perseus.cm_group (
    group_id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL,
    domain_id CHAR(32) NOT NULL,
    is_active BOOLEAN NOT NULL,
    last_modified TIMESTAMPTZ NOT NULL
);
