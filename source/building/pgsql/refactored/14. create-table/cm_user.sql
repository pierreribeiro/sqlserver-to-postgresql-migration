-- Table: perseus.cm_user
-- Source: SQL Server [dbo].[cm_user]
-- Columns: 7

CREATE TABLE IF NOT EXISTS perseus.cm_user (
    user_id INTEGER GENERATED ALWAYS AS IDENTITY,
    domain_id CHAR(32),
    is_active BOOLEAN NOT NULL,
    name VARCHAR(255) NOT NULL,
    login VARCHAR(50),
    email VARCHAR(255),
    object_id UUID
);
