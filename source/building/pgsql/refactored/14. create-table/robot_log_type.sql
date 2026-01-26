-- ============================================================================
-- Object: robot_log_type
-- Type: TABLE
-- Priority: P2
-- Description: Robot operation type definitions (transfer, read, move, etc.)
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/73. perseus.dbo.robot_log_type.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/66. perseus.robot_log_type.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: container_type
--   Referenced by: robot_log, robot operation tracking
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, VARCHAR for indexed columns, BOOLEAN for flags
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.robot_log_type)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Lookup table for robot operation types
--   Indexes: PRIMARY KEY on id
--   Future indexes: name (for operation lookups), destination_container_type_id (for FK joins)
--   Expected: Very low-volume table (~10-50 rows)
-- ============================================================================
-- Data Type Decisions:
--   - name: VARCHAR(150) NOT CITEXT - operation type names are standardized
--   - auto_process: BOOLEAN NOT INTEGER - flag for automatic processing
--   - destination_container_type_id: INTEGER - target container type for operation
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed VARCHAR columns from CITEXT to VARCHAR
--   2026-01-26 Claude - Changed auto_process from INTEGER to BOOLEAN
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.robot_log_type CASCADE;

-- Create robot_log_type table
CREATE TABLE perseus.robot_log_type (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Operation type definition
    name VARCHAR(150) NOT NULL,

    -- Processing configuration
    auto_process BOOLEAN NOT NULL,
    destination_container_type_id INTEGER,

    -- Primary key constraint
    CONSTRAINT pk_robot_log_type PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.robot_log_type IS
'Robot operation type definitions (transfer, read, move, consolidate, etc.).
Defines types of operations that robots can perform on containers and materials.
Each operation type may specify automatic processing rules and target container types.
Referenced by: robot_log (operation tracking), robot workflow automation.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.robot_log_type.id IS
'Primary key - unique identifier for robot operation type (auto-increment)';

COMMENT ON COLUMN perseus.robot_log_type.name IS
'Operation type name (e.g., "Liquid Transfer", "Barcode Read", "Container Move", "Plate Consolidation")';

COMMENT ON COLUMN perseus.robot_log_type.auto_process IS
'Automatic processing flag - TRUE if operation triggers automated post-processing, FALSE if manual verification required';

COMMENT ON COLUMN perseus.robot_log_type.destination_container_type_id IS
'Foreign key to container_type table - target container type for this operation (NULL if not applicable)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'robot_log_type'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'robot_log_type';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.robot_log_type CASCADE;

-- ============================================================================
-- END OF robot_log_type TABLE DDL
-- ============================================================================
