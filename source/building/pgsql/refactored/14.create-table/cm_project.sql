-- Table: perseus.cm_project
-- Source: SQL Server [dbo].[cm_project]
-- Columns: 5

CREATE TABLE IF NOT EXISTS perseus.cm_project (
    project_id SMALLINT NOT NULL,
    label VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL,
    display_order SMALLINT NOT NULL,
    group_id INTEGER
);
