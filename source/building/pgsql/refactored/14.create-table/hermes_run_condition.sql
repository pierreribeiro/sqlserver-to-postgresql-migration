-- Foreign Table: hermes.run_condition
-- Source: SQL Server [hermes].[run_condition]
-- Columns: 4
-- FDW Server: hermes_server

CREATE FOREIGN TABLE IF NOT EXISTS hermes.run_condition (
    id INTEGER NOT NULL,
    default_value NUMERIC(11,3),
    condition_set_id INTEGER,
    master_condition_id INTEGER
) SERVER hermes_server
OPTIONS (schema_name 'hermes', table_name 'run_condition');
