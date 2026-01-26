-- ============================================================================
-- Object: container_type
-- Type: TABLE
-- Priority: P1 (High - referenced by container, robot_log_type)
-- Description: Container type definitions (plates, tubes, flasks, etc.)
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/perseus.dbo.container_type.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/15. perseus.container_type.sql
--   Quality Score: 8.5/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: None (Tier 0)
--   Referenced by: container, container_type_position, robot_log_type
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, BOOLEAN not INTEGER
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.container_type)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   - Lookup table (20-50 rows)
--   - Frequently joined by container table
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed CITEXT to VARCHAR (indexed column)
--   2026-01-26 Claude - Changed INTEGER boolean flags to BOOLEAN type
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.container_type CASCADE;

-- Create container_type table
CREATE TABLE perseus.container_type (
    -- Primary key with IDENTITY
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Container type name
    name VARCHAR(100) NOT NULL,

    -- Container characteristics (boolean flags)
    is_parent BOOLEAN NOT NULL DEFAULT TRUE,
    is_equipment BOOLEAN NOT NULL DEFAULT FALSE,
    is_single BOOLEAN NOT NULL DEFAULT TRUE,
    is_restricted BOOLEAN NOT NULL DEFAULT FALSE,
    is_gooable BOOLEAN NOT NULL DEFAULT FALSE,

    -- Primary key constraint
    CONSTRAINT pk_container_type PRIMARY KEY (id)
);

-- ============================================================================
-- Indexes
-- ============================================================================

-- Index on name for lookups
CREATE INDEX idx_container_type_name ON perseus.container_type(name);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.container_type IS
'Container type definitions (plates, tubes, flasks, etc.).
Referenced by: container, container_type_position, robot_log_type.
Lookup table with 20-50 rows.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.container_type.id IS
'Primary key - unique identifier for container type (auto-increment)';

COMMENT ON COLUMN perseus.container_type.name IS
'Container type name (e.g., "96-well plate", "50mL tube", "2L flask")';

COMMENT ON COLUMN perseus.container_type.is_parent IS
'True if this container type can contain other containers (default: TRUE)';

COMMENT ON COLUMN perseus.container_type.is_equipment IS
'True if this container type represents equipment (default: FALSE)';

COMMENT ON COLUMN perseus.container_type.is_single IS
'True if this container type is a single unit (default: TRUE)';

COMMENT ON COLUMN perseus.container_type.is_restricted IS
'True if this container type has restricted access (default: FALSE)';

COMMENT ON COLUMN perseus.container_type.is_gooable IS
'True if this container type can hold materials directly (default: FALSE)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'container_type'
-- ORDER BY ordinal_position;

-- ============================================================================
-- END OF container_type TABLE DDL
-- ============================================================================
