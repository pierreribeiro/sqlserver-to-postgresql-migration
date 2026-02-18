-- Table: perseus.permissions
-- Source: SQL Server [dbo].[Permissions]
-- Columns: 2

CREATE TABLE IF NOT EXISTS perseus.permissions (
    email_address VARCHAR(255) NOT NULL,
    permission CHAR(1) NOT NULL
);
