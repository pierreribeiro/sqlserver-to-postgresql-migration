-- Table: perseus.robot_log_type
-- Source: SQL Server [dbo].[robot_log_type]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.robot_log_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(150) NOT NULL,
    auto_process INTEGER NOT NULL,
    destination_container_type_id INTEGER
);
