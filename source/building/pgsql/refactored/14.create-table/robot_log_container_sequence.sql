-- Table: perseus.robot_log_container_sequence
-- Source: SQL Server [dbo].[robot_log_container_sequence]
-- Columns: 5

CREATE TABLE IF NOT EXISTS perseus.robot_log_container_sequence (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    container_id INTEGER NOT NULL,
    sequence_type_id INTEGER NOT NULL,
    processed_on TIMESTAMPTZ
);
