-- Foreign Table: hermes.run_condition_value
-- Source: SQL Server [hermes].[run_condition_value]
-- Columns: 5
-- FDW Server: hermes_server

CREATE FOREIGN TABLE IF NOT EXISTS hermes.run_condition_value (
    id INTEGER NOT NULL,
    value NUMERIC(11,3),
    master_condition_id INTEGER,
    updated_on TIMESTAMP,
    run_id INTEGER
) SERVER hermes_server
OPTIONS (schema_name 'hermes', table_name 'run_condition_value');
