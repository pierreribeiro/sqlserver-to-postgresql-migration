-- ============================================================================
-- Object: fatsmurf
-- Type: TABLE
-- Priority: P0 CRITICAL
-- Description: Fermentation experiment runs - FK target for material_transition/transition_material
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/23. perseus.dbo.fatsmurf.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/20. perseus.fatsmurf.sql
--   Quality Score: 8.5/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: smurf, container, manufacturer, workflow_step
--   Referenced by: material_transition, transition_material, fatsmurf_attachment,
--                  fatsmurf_comment, fatsmurf_history, fatsmurf_reading, poll
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, no implicit conversions
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.fatsmurf)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: High-volume fermentation experiment tracking
--   Indexes: PRIMARY KEY on id, UNIQUE INDEX on uid (REQUIRED for FK references)
--   Future indexes: smurf_id, added_by, container_id, workflow_step_id, added_on
--   Expected: Moderate-volume table with frequent lineage queries
-- ============================================================================
-- Data Type Decisions:
--   - uid: VARCHAR(50) NOT CITEXT - **CRITICAL FK target** for material_transition/transition_material
--   - name: VARCHAR(150) NOT CITEXT - frequently used in searches
--   - description: VARCHAR(500) NOT TEXT - bounded field
--   - added_on/run_on/updated_on/inserted_on: TIMESTAMP - CURRENT_TIMESTAMP not clock_timestamp()
--   - duration: DOUBLE PRECISION - floating point hours
--   - run_complete: TIMESTAMP - computed column converted to regular column (non-deterministic)
--   - organization_id: INTEGER DEFAULT 1 - organization assignment
-- ============================================================================
-- CRITICAL NOTE: Computed Column Handling
--   SQL Server computed column: run_complete = CASE WHEN duration IS NULL THEN GETDATE()
--                                                    ELSE DATEADD(minute, duration*60, run_on) END
--   PostgreSQL: Cannot use GENERATED column (GETDATE()/CURRENT_TIMESTAMP not IMMUTABLE)
--   Solution: Regular column - populate via trigger or application logic
--   Alternative: Use GENERATED column with run_on + duration only (exclude NULL case)
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed uid from CITEXT to VARCHAR(50) (FK target)
--   2026-01-26 Claude - Changed name from CITEXT to VARCHAR(150) (performance)
--   2026-01-26 Claude - Changed description from CITEXT to VARCHAR(500)
--   2026-01-26 Claude - Changed clock_timestamp() to CURRENT_TIMESTAMP
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added UNIQUE INDEX on uid (REQUIRED for FK references)
--   2026-01-26 Claude - Converted computed column run_complete to regular column
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.fatsmurf CASCADE;

-- Create fatsmurf table
CREATE TABLE perseus.fatsmurf (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Experiment identification
    smurf_id INTEGER NOT NULL,
    uid VARCHAR(50) NOT NULL,
    name VARCHAR(150),
    description VARCHAR(500),

    -- Experiment execution
    run_on TIMESTAMP,
    duration DOUBLE PRECISION,
    run_complete TIMESTAMP,

    -- Recycling and sampling
    recycled_bottoms_id INTEGER,
    themis_sample_id INTEGER,

    -- Ownership and tracking
    added_by INTEGER NOT NULL,
    organization_id INTEGER DEFAULT 1,

    -- Location and workflow
    container_id INTEGER,
    workflow_step_id INTEGER,

    -- External system reference
    triton_task_id INTEGER,

    -- Timestamps
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inserted_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Primary key constraint
    CONSTRAINT pk_fatsmurf PRIMARY KEY (id)
);

-- ============================================================================
-- CRITICAL INDEX: uid column MUST be unique for FK references
-- ============================================================================

-- UNIQUE index on uid - REQUIRED for material_transition and transition_material FKs
CREATE UNIQUE INDEX idx_fatsmurf_uid ON perseus.fatsmurf(uid);

-- ============================================================================
-- Additional Performance Indexes
-- ============================================================================

-- Index on smurf_id for method lookups
CREATE INDEX idx_fatsmurf_smurf_id ON perseus.fatsmurf(smurf_id);

-- Index on added_on for temporal queries
CREATE INDEX idx_fatsmurf_added_on ON perseus.fatsmurf(added_on);

-- Index on container_id for location queries
CREATE INDEX idx_fatsmurf_container_id ON perseus.fatsmurf(container_id);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.fatsmurf IS
'Fermentation experiment runs - central to fermentation tracking system.
Stores all fermentation experiments (smurfs executed with specific parameters).
Lineage relationships tracked via material_transition and transition_material tables.
Referenced by: 5+ child tables including material lineage tracking tables.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.fatsmurf.id IS
'Primary key - unique identifier for fermentation experiment (auto-increment)';

COMMENT ON COLUMN perseus.fatsmurf.uid IS
'Unique identifier string - used as FK reference in material_transition and transition_material.
MUST remain UNIQUE - enforced by idx_fatsmurf_uid index.';

COMMENT ON COLUMN perseus.fatsmurf.smurf_id IS
'Foreign key to smurf table - method/protocol definition for this experiment';

COMMENT ON COLUMN perseus.fatsmurf.name IS
'Experiment name/label (e.g., "Batch A-123", "Fed-batch optimization")';

COMMENT ON COLUMN perseus.fatsmurf.description IS
'Free-text description of experiment';

COMMENT ON COLUMN perseus.fatsmurf.run_on IS
'Timestamp when experiment started';

COMMENT ON COLUMN perseus.fatsmurf.duration IS
'Experiment duration in hours (decimal)';

COMMENT ON COLUMN perseus.fatsmurf.run_complete IS
'Computed completion timestamp (originally: run_on + duration OR current time if duration NULL).
NOTE: Converted from computed column to regular column (populate via trigger or application).';

COMMENT ON COLUMN perseus.fatsmurf.recycled_bottoms_id IS
'Foreign key to goo table - recycled bottoms material used as input';

COMMENT ON COLUMN perseus.fatsmurf.themis_sample_id IS
'External system reference - Themis sample identifier';

COMMENT ON COLUMN perseus.fatsmurf.added_by IS
'Foreign key to perseus_user table - user who created this experiment';

COMMENT ON COLUMN perseus.fatsmurf.organization_id IS
'Organization identifier (default: 1)';

COMMENT ON COLUMN perseus.fatsmurf.container_id IS
'Foreign key to container table - physical container for experiment';

COMMENT ON COLUMN perseus.fatsmurf.workflow_step_id IS
'Foreign key to workflow_step table - current workflow status';

COMMENT ON COLUMN perseus.fatsmurf.triton_task_id IS
'External system reference - Triton task identifier';

COMMENT ON COLUMN perseus.fatsmurf.added_on IS
'Timestamp when experiment record was created (default: current timestamp)';

COMMENT ON COLUMN perseus.fatsmurf.updated_on IS
'Timestamp when experiment record was last updated (default: current timestamp)';

COMMENT ON COLUMN perseus.fatsmurf.inserted_on IS
'Timestamp when experiment record was first inserted (default: current timestamp)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'fatsmurf'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'fatsmurf';

-- Verify unique index on uid
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'perseus' AND tablename = 'fatsmurf';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP INDEX IF EXISTS perseus.idx_fatsmurf_container_id;
-- DROP INDEX IF EXISTS perseus.idx_fatsmurf_added_on;
-- DROP INDEX IF EXISTS perseus.idx_fatsmurf_smurf_id;
-- DROP INDEX IF EXISTS perseus.idx_fatsmurf_uid;
-- DROP TABLE IF EXISTS perseus.fatsmurf CASCADE;

-- ============================================================================
-- END OF fatsmurf TABLE DDL
-- ============================================================================
