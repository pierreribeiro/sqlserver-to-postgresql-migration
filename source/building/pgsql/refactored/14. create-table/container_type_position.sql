-- ============================================================================
-- Object: container_type_position
-- Type: TABLE
-- Priority: P2
-- Description: Defines valid position layouts for container type hierarchies
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/19. perseus.dbo.container_type_position.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/16. perseus.container_type_position.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: container_type
--   Referenced by: Container position validation logic
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, VARCHAR for position coordinates
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.container_type_position)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Configuration table for container position layouts
--   Indexes: PRIMARY KEY on id
--   Future indexes: (parent_container_type_id, child_container_type_id), position_name
--   Expected: Low-volume table (~100-500 rows)
-- ============================================================================
-- Data Type Decisions:
--   - parent_container_type_id: INTEGER NOT NULL - parent container type (e.g., rack)
--   - child_container_type_id: INTEGER - child container type that can fit (e.g., plate)
--   - position_*: VARCHAR(50) - alphanumeric position coordinates
-- ============================================================================
-- Business Logic:
--   Defines valid parent-child relationships between container types.
--   Example: "96-well plate" can fit in "plate rack" at positions A1-H12.
--   Null child_container_type_id = position allows direct material storage.
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed VARCHAR columns from CITEXT to VARCHAR
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.container_type_position CASCADE;

-- Create container_type_position table
CREATE TABLE perseus.container_type_position (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Container type hierarchy
    parent_container_type_id INTEGER NOT NULL,
    child_container_type_id INTEGER,

    -- Position layout (alphanumeric coordinates)
    position_name VARCHAR(50),
    position_x_coordinate VARCHAR(50),
    position_y_coordinate VARCHAR(50),

    -- Primary key constraint
    CONSTRAINT pk_container_type_position PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.container_type_position IS
'Defines valid position layouts for container type hierarchies.
Specifies which child container types can fit into parent container types at specific positions.
Example: "96-well plate" (child) fits in "plate rack" (parent) at positions A1-H12.
Null child_container_type_id = position allows direct material storage (no nested container).
Referenced by: Container position validation, container hierarchy management.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.container_type_position.id IS
'Primary key - unique identifier for container position definition (auto-increment)';

COMMENT ON COLUMN perseus.container_type_position.parent_container_type_id IS
'Foreign key to container_type table - parent container type (e.g., "plate rack", "freezer")';

COMMENT ON COLUMN perseus.container_type_position.child_container_type_id IS
'Foreign key to container_type table - child container type that can occupy this position (NULL = direct material storage)';

COMMENT ON COLUMN perseus.container_type_position.position_name IS
'Position identifier (e.g., "A1", "Shelf 3", "Drawer 2-B")';

COMMENT ON COLUMN perseus.container_type_position.position_x_coordinate IS
'X-axis coordinate for position (alphanumeric, e.g., "A", "1", "Column-12")';

COMMENT ON COLUMN perseus.container_type_position.position_y_coordinate IS
'Y-axis coordinate for position (alphanumeric, e.g., "1", "12", "Row-8")';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'container_type_position'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'container_type_position';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.container_type_position CASCADE;

-- ============================================================================
-- END OF container_type_position TABLE DDL
-- ============================================================================
