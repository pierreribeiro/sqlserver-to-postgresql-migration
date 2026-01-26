-- ============================================================================
-- Object: container_history
-- Type: TABLE
-- Priority: P2
-- Description: Links history events to container records (audit trail junction)
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/17. perseus.dbo.container_history.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/14. perseus.container_history.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: history, container
--   Referenced by: Audit trail queries for container changes
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, INTEGER for FKs
--   [✓] III. Set-Based - Junction table supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.container_history)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single junction table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Junction table linking history events to containers
--   Indexes: PRIMARY KEY on id
--   Future indexes: history_id, container_id (for FK joins and lookups)
--   Expected: Medium-volume table with frequent INSERT during container operations
-- ============================================================================
-- Data Type Decisions:
--   - id: INTEGER GENERATED ALWAYS AS IDENTITY - sequential junction ID
--   - history_id: INTEGER NOT NULL - FK to history master table
--   - container_id: INTEGER NOT NULL - FK to container table
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.container_history CASCADE;

-- Create container_history table
CREATE TABLE perseus.container_history (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Foreign keys to history and container
    history_id INTEGER NOT NULL,
    container_id INTEGER NOT NULL,

    -- Primary key constraint
    CONSTRAINT pk_container_history PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.container_history IS
'Junction table linking history events to container records.
Tracks audit trail for container operations (creation, updates, relocations, deletions).
Each row represents one container affected by a history event.
History event details in history table, container details in container table.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.container_history.id IS
'Primary key - unique identifier for container-history junction (auto-increment)';

COMMENT ON COLUMN perseus.container_history.history_id IS
'Foreign key to history table - audit event that affected this container';

COMMENT ON COLUMN perseus.container_history.container_id IS
'Foreign key to container table - container affected by this event';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'container_history'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'container_history';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.container_history CASCADE;

-- ============================================================================
-- END OF container_history TABLE DDL
-- ============================================================================
