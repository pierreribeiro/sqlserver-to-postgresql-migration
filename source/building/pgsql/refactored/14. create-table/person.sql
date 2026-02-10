-- Table: perseus.person
-- Source: SQL Server [dbo].[person]
-- Columns: 8

CREATE TABLE IF NOT EXISTS perseus.person (
    id INTEGER NOT NULL,
    domain_id CHAR(32) NOT NULL,
    km_session_id CHAR(32),
    login VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(254),
    last_login TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);
