-- ============================================================================
-- Object: container
-- Type: TABLE
-- Priority: P0
-- Description: Storage container instances (plates, tubes, flasks, etc.)
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/16. perseus.dbo.container.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/13. perseus.container.sql
--   Quality Score: 8.5/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: container_type
--   Referenced by: goo, container_history, robot_log_container_sequence,
--                  robot_log_read, robot_log_transfer, fatsmurf
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, VARCHAR not CITEXT for indexed columns
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.container)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Frequently accessed for material location tracking
--   Indexes: PRIMARY KEY on id, UNIQUE INDEX on uid (required for FKs)
--   Future indexes: container_type_id, position_name (for location queries)
--   Expected: Medium-volume table with frequent JOINs
-- ============================================================================
-- Data Type Decisions:
--   - uid: VARCHAR(50) NOT CITEXT - used as FK reference, indexed
--   - name: VARCHAR(128) NOT CITEXT - frequently used in JOINs/WHERE
--   - scope_id: VARCHAR(50) with DEFAULT gen_random_uuid() - unique container scope identifier
--   - position_*: VARCHAR(50) NOT CITEXT - position coordinates (alphanumeric)
--   - created_on: TIMESTAMP with CURRENT_TIMESTAMP - transaction-consistent timestamp
--   - mass: DOUBLE PRECISION - floating point measurement
--   - left_id/right_id/depth: INTEGER - nested set model fields for hierarchy
-- ============================================================================
-- Critical Fix:
--   SQL Server: scope_id DEFAULT (newid()) - generates unique GUID
--   AWS SCT: scope_id DEFAULT aws_sqlserver_ext.newid() - INVALID (extension function)
--   PostgreSQL: scope_id DEFAULT gen_random_uuid()::VARCHAR(50) - native UUID generation
--   Note: gen_random_uuid() requires pgcrypto extension or PostgreSQL 13+
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed VARCHAR columns from CITEXT to VARCHAR (performance)
--   2026-01-26 Claude - Fixed scope_id: newid() → gen_random_uuid()::VARCHAR(50)
--   2026-01-26 Claude - Changed clock_timestamp() to CURRENT_TIMESTAMP
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added UNIQUE INDEX on uid column
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.container CASCADE;

-- Create container table
CREATE TABLE perseus.container (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Container classification
    container_type_id INTEGER NOT NULL,

    -- Container identification
    name VARCHAR(128),
    uid VARCHAR(50) NOT NULL,

    -- Nested set model fields (for hierarchical container relationships)
    left_id INTEGER NOT NULL DEFAULT 1,
    right_id INTEGER NOT NULL DEFAULT 2,
    depth INTEGER NOT NULL DEFAULT 0,
    scope_id VARCHAR(50) NOT NULL DEFAULT gen_random_uuid()::VARCHAR(50),

    -- Physical properties
    mass DOUBLE PRECISION,

    -- Position/Location (alphanumeric coordinates)
    position_name VARCHAR(50),
    position_x_coordinate VARCHAR(50),
    position_y_coordinate VARCHAR(50),

    -- Timestamps
    created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Primary key constraint
    CONSTRAINT pk_container PRIMARY KEY (id)
);

-- ============================================================================
-- Critical Index: uid column MUST be unique for FK references
-- ============================================================================

-- UNIQUE index on uid - REQUIRED for potential FK references
CREATE UNIQUE INDEX idx_container_uid ON perseus.container(uid);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.container IS
'Storage container instances (plates, tubes, flasks, racks, freezers, etc.).
Uses nested set model (left_id, right_id, depth, scope_id) for hierarchical relationships.
Material locations tracked via goo.container_id FK reference.
Referenced by: goo, container_history, robot_log operations.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.container.id IS
'Primary key - unique identifier for container (auto-increment)';

COMMENT ON COLUMN perseus.container.container_type_id IS
'Foreign key to container_type table - type of container (plate, tube, rack, etc.)';

COMMENT ON COLUMN perseus.container.name IS
'Container name/label (e.g., "Freezer A1", "Plate-12345")';

COMMENT ON COLUMN perseus.container.uid IS
'Unique identifier string - MUST be unique (enforced by idx_container_uid).
Used for barcode tracking and potential FK references.';

COMMENT ON COLUMN perseus.container.left_id IS
'Nested set model - left boundary for hierarchical queries (default: 1)';

COMMENT ON COLUMN perseus.container.right_id IS
'Nested set model - right boundary for hierarchical queries (default: 2)';

COMMENT ON COLUMN perseus.container.depth IS
'Nested set model - depth level in container hierarchy (default: 0 = root)';

COMMENT ON COLUMN perseus.container.scope_id IS
'Nested set model - scope identifier for isolated subtrees.
Generated via gen_random_uuid() to ensure uniqueness across container hierarchies.
Note: Requires PostgreSQL 13+ or pgcrypto extension.';

COMMENT ON COLUMN perseus.container.mass IS
'Container mass in kilograms (for tare weight calculations)';

COMMENT ON COLUMN perseus.container.position_name IS
'Position name within parent container (e.g., "A1", "B12", "Shelf 3")';

COMMENT ON COLUMN perseus.container.position_x_coordinate IS
'X-axis coordinate for position (alphanumeric, e.g., "A", "1", "A1")';

COMMENT ON COLUMN perseus.container.position_y_coordinate IS
'Y-axis coordinate for position (alphanumeric, e.g., "1", "12")';

COMMENT ON COLUMN perseus.container.created_on IS
'Timestamp when container was created (default: current timestamp)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'container'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'container';

-- Verify unique index on uid
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'perseus' AND tablename = 'container';

-- Test gen_random_uuid() function
-- SELECT gen_random_uuid()::VARCHAR(50) AS test_scope_id;

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP INDEX IF EXISTS perseus.idx_container_uid;
-- DROP TABLE IF EXISTS perseus.container CASCADE;

-- ============================================================================
-- END OF container TABLE DDL
-- ============================================================================
