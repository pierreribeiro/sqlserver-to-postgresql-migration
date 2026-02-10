-- Foreign Table: hermes.run_condition_option
-- Source: SQL Server [hermes].[run_condition_option]
-- Columns: 4
-- FDW Server: hermes_server

CREATE FOREIGN TABLE IF NOT EXISTS hermes.run_condition_option (
    id INTEGER NOT NULL,
    value NUMERIC(11,3),
    label VARCHAR(500),
    master_condition_id INTEGER
) SERVER hermes_server
OPTIONS (schema_name 'hermes', table_name 'run_condition_option');
