-- Table: perseus.m_upstream
-- Source: SQL Server [dbo].[m_upstream]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.m_upstream (
    start_point VARCHAR(50) NOT NULL,
    end_point VARCHAR(50) NOT NULL,
    path VARCHAR(500) NOT NULL,
    level INTEGER NOT NULL
);
