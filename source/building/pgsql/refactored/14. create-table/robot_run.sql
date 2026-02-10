-- Table: perseus.robot_run
-- Source: SQL Server [dbo].[robot_run]
-- Columns: 5

CREATE TABLE IF NOT EXISTS perseus.robot_run (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    robot_id INTEGER,
    name VARCHAR(100) NOT NULL,
    all_qc_passed BOOLEAN,
    all_themis_submitted BOOLEAN
);
