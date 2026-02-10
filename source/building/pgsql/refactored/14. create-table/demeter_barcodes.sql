-- Foreign Table: demeter.barcodes
-- Source: SQL Server [demeter].[barcodes]
-- Columns: 3
-- FDW Server: demeter_server

CREATE FOREIGN TABLE IF NOT EXISTS demeter.barcodes (
    id INTEGER NOT NULL,
    barcode VARCHAR(50) NOT NULL,
    seedvial_id INTEGER NOT NULL
) SERVER demeter_server
OPTIONS (schema_name 'demeter', table_name 'barcodes');
