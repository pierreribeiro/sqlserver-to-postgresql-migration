-- Table: perseus.m_downstream
-- Source: SQL Server [dbo].[m_downstream]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.m_downstream (
    start_point VARCHAR(50) NOT NULL,
    end_point VARCHAR(50) NOT NULL,
    path VARCHAR(500) NOT NULL,
    level INTEGER NOT NULL
);
