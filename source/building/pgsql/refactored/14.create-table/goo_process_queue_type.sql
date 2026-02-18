-- Table: perseus.goo_process_queue_type
-- Source: SQL Server [dbo].[goo_process_queue_type]
-- Columns: 2

CREATE TABLE IF NOT EXISTS perseus.goo_process_queue_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(50) NOT NULL
);
