-- Table: perseus.workflow_section
-- Source: SQL Server [dbo].[workflow_section]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.workflow_section (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    workflow_id INTEGER NOT NULL,
    name VARCHAR(150) NOT NULL,
    starting_step_id INTEGER NOT NULL
);
