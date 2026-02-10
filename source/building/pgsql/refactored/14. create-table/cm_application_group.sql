-- Table: perseus.cm_application_group
-- Source: SQL Server [dbo].[cm_application_group]
-- Columns: 2

CREATE TABLE IF NOT EXISTS perseus.cm_application_group (
    application_group_id INTEGER GENERATED ALWAYS AS IDENTITY,
    label VARCHAR(50) NOT NULL
);
