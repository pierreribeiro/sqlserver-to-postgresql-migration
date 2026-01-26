-- ============================================================================
-- Object: display_type
-- Type: TABLE
-- Priority: P2 (Medium - UI configuration)
-- Description: Display type definitions for field mapping system
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/perseus.dbo.display_type.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/18. perseus.display_type.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: None (Tier 0)
--   Referenced by: field_map_display_type
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types (VARCHAR not CITEXT)
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.display_type)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   - Lookup table (small, 5-10 rows)
--   - Infrequently updated
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed CITEXT to VARCHAR
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.display_type CASCADE;

-- Create display_type table
CREATE TABLE perseus.display_type (
    -- Primary key
    id INTEGER NOT NULL,

    -- Display type name
    name VARCHAR(100) NOT NULL,

    -- Primary key constraint
    CONSTRAINT pk_display_type PRIMARY KEY (id)
);

-- ============================================================================
-- Indexes
-- ============================================================================

-- Index on name for lookups
CREATE INDEX idx_display_type_name ON perseus.display_type(name);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.display_type IS
'Display type definitions for field mapping system (e.g., "text", "dropdown", "date").
Referenced by: field_map_display_type.
Lookup table with 5-10 rows.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.display_type.id IS
'Primary key - unique identifier for display type';

COMMENT ON COLUMN perseus.display_type.name IS
'Display type name (e.g., "text", "dropdown", "date", "checkbox")';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'display_type'
-- ORDER BY ordinal_position;

-- ============================================================================
-- END OF display_type TABLE DDL
-- ============================================================================
