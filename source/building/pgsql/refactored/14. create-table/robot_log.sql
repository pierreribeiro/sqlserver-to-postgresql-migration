-- Table: perseus.robot_log
-- Source: SQL Server [dbo].[robot_log]
-- Columns: 14

CREATE TABLE IF NOT EXISTS perseus.robot_log (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    class_id INTEGER NOT NULL,
    source VARCHAR(250),
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    log_text TEXT NOT NULL,
    file_name VARCHAR(250),
    robot_log_checksum VARCHAR(32),
    started_on TIMESTAMP,
    completed_on TIMESTAMP,
    loaded_on TIMESTAMP,
    loaded INTEGER NOT NULL DEFAULT 0,
    loadable INTEGER NOT NULL DEFAULT 0,
    robot_run_id INTEGER,
    robot_log_type_id INTEGER NOT NULL
);
