-- Table: perseus.robot_log_error
-- Source: SQL Server [dbo].[robot_log_error]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.robot_log_error (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    error_text TEXT NOT NULL
);
