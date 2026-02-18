-- Table: perseus.perseus_user
-- Source: SQL Server [dbo].[perseus_user]
-- Columns: 9

CREATE TABLE IF NOT EXISTS perseus.perseus_user (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(128) NOT NULL,
    domain_id VARCHAR(250),
    login VARCHAR(50),
    mail VARCHAR(50),
    admin INTEGER NOT NULL DEFAULT 0,
    super INTEGER NOT NULL DEFAULT 0,
    common_id INTEGER,
    manufacturer_id INTEGER NOT NULL DEFAULT 1
);
