-- Foreign Table: hermes.run_master_condition
-- Source: SQL Server [hermes].[run_master_condition]
-- Columns: 10
-- FDW Server: hermes_server

CREATE FOREIGN TABLE IF NOT EXISTS hermes.run_master_condition (
    id INTEGER NOT NULL,
    name TEXT,
    units VARCHAR(25),
    description VARCHAR(250),
    optional_order INTEGER,
    created_on TIMESTAMP,
    available_in_view BOOLEAN,
    creator_id INTEGER,
    condition_type_id INTEGER,
    active BOOLEAN
) SERVER hermes_server
OPTIONS (schema_name 'hermes', table_name 'run_master_condition');
