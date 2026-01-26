-- ============================================================================
-- Object: color
-- Type: TABLE
-- Priority: P2 (Medium - UI configuration)
-- Description: Color definitions for UI elements
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/perseus.dbo.color.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/12. perseus.color.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: None (Tier 0)
--   Referenced by: UI display configurations
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types (VARCHAR not CITEXT)
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.color)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   - Lookup table (small, 10-20 rows)
--   - Infrequently updated
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed CITEXT to VARCHAR (color names are case-sensitive)
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.color CASCADE;

-- Create color table
CREATE TABLE perseus.color (
    -- Color name as primary key
    name VARCHAR(50) NOT NULL,

    -- Primary key constraint
    CONSTRAINT pk_color PRIMARY KEY (name)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.color IS
'Color definitions for UI elements in Perseus application.
Lookup table with 10-20 standard color names.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.color.name IS
'Color name (e.g., "red", "blue", "green") - used as primary key';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'color'
-- ORDER BY ordinal_position;

-- ============================================================================
-- END OF color TABLE DDL
-- ============================================================================
