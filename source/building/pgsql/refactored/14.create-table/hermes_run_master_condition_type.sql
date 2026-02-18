-- Foreign Table: hermes.run_master_condition_type
-- Source: SQL Server [hermes].[run_master_condition_type]
-- Columns: 3
-- FDW Server: hermes_server

CREATE FOREIGN TABLE IF NOT EXISTS hermes.run_master_condition_type (
    id INTEGER NOT NULL,
    name TEXT,
    optional_order INTEGER
) SERVER hermes_server
OPTIONS (schema_name 'hermes', table_name 'run_master_condition_type');
