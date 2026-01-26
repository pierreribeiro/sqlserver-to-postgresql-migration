-- ============================================================================
-- Object: perseus_user
-- Type: TABLE
-- Priority: P0 (CRITICAL - referenced by most tables)
-- Description: User accounts and authentication information
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/perseus.dbo.perseus_user.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/56. perseus.perseus_user.sql
--   Quality Score: 8.5/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: manufacturer (FK for manufacturer_id)
--   Referenced by: Most tables (history, goo, workflow, etc.) - 50+ tables
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, BOOLEAN not INTEGER
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.perseus_user)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   - Core authentication table (100-500 rows)
--   - Frequently joined by most application tables
--   - Index on login for authentication lookups
--   - Index on mail for email-based lookups
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed login/mail to VARCHAR (case-sensitive)
--   2026-01-26 Claude - Name kept as VARCHAR (case-sensitive for proper names)
--   2026-01-26 Claude - Changed INTEGER boolean flags to BOOLEAN type
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.perseus_user CASCADE;

-- Create perseus_user table
CREATE TABLE perseus.perseus_user (
    -- Primary key with IDENTITY
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- User identification
    name VARCHAR(200) NOT NULL,
    domain_id VARCHAR(100),
    login VARCHAR(100),
    mail VARCHAR(200),

    -- User roles (boolean flags)
    admin BOOLEAN NOT NULL DEFAULT FALSE,
    super BOOLEAN NOT NULL DEFAULT FALSE,

    -- Cross-system identifiers
    common_id INTEGER,
    manufacturer_id INTEGER NOT NULL DEFAULT 1,

    -- Primary key constraint
    CONSTRAINT pk_perseus_user PRIMARY KEY (id)
);

-- ============================================================================
-- Indexes
-- ============================================================================

-- Index on login for authentication lookups
CREATE UNIQUE INDEX idx_perseus_user_login ON perseus.perseus_user(login)
    WHERE login IS NOT NULL;

-- Index on mail for email-based lookups
CREATE INDEX idx_perseus_user_mail ON perseus.perseus_user(mail)
    WHERE mail IS NOT NULL;

-- Index on name for user searches
CREATE INDEX idx_perseus_user_name ON perseus.perseus_user(name);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.perseus_user IS
'CRITICAL TABLE: User accounts and authentication information.
Referenced by 50+ tables throughout Perseus system.
User roles: admin (elevated privileges), super (superuser access).
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.perseus_user.id IS
'Primary key - unique identifier for user (auto-increment)';

COMMENT ON COLUMN perseus.perseus_user.name IS
'User full name (e.g., "John Smith")';

COMMENT ON COLUMN perseus.perseus_user.domain_id IS
'Active Directory or domain identifier';

COMMENT ON COLUMN perseus.perseus_user.login IS
'Login username - UNIQUE (case-sensitive)';

COMMENT ON COLUMN perseus.perseus_user.mail IS
'Email address for user';

COMMENT ON COLUMN perseus.perseus_user.admin IS
'True if user has admin privileges (default: FALSE)';

COMMENT ON COLUMN perseus.perseus_user.super IS
'True if user has superuser privileges (default: FALSE)';

COMMENT ON COLUMN perseus.perseus_user.common_id IS
'Common identifier across multiple systems';

COMMENT ON COLUMN perseus.perseus_user.manufacturer_id IS
'Foreign key to manufacturer table - user organization (default: 1)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'perseus_user'
-- ORDER BY ordinal_position;

-- Verify indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'perseus' AND tablename = 'perseus_user';

-- ============================================================================
-- END OF perseus_user TABLE DDL
-- ============================================================================
