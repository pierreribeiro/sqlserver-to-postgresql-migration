-- ============================================================================
-- Object: history
-- Type: TABLE
-- Priority: P2
-- Description: Master audit trail table for tracking changes across system
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/44. perseus.dbo.history.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/41. perseus.history.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: history_type, perseus_user
--   Referenced by: goo_history, container_history, fatsmurf_history, poll_history,
--                  history_value (key-value details)
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, TIMESTAMP for audit trail
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.history)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: High-volume audit trail table (500,000+ rows)
--   Indexes: PRIMARY KEY on id
--   Future indexes: history_type_id, creator_id, created_on (for temporal queries)
--   Expected: Append-only table with frequent INSERT, infrequent SELECT
--   Optimization: Consider partitioning by created_on for historical data
-- ============================================================================
-- Data Type Decisions:
--   - id: INTEGER GENERATED ALWAYS AS IDENTITY - sequential audit ID
--   - history_type_id: INTEGER NOT NULL - event type classification
--   - creator_id: INTEGER NOT NULL - user who triggered event
--   - created_on: TIMESTAMP NOT NULL with CURRENT_TIMESTAMP - event timestamp
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed getdate() to CURRENT_TIMESTAMP
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.history CASCADE;

-- Create history table
CREATE TABLE perseus.history (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Event classification
    history_type_id INTEGER NOT NULL,

    -- Audit trail
    creator_id INTEGER NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Primary key constraint
    CONSTRAINT pk_history PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.history IS
'Master audit trail table for tracking changes across Perseus system.
Records all significant events (material creation, updates, deletions, workflow changes).
Event details stored in child tables (goo_history, container_history, etc.) and history_value.
High-volume table (500,000+ rows) - consider partitioning by created_on for performance.
Referenced by: goo_history, container_history, fatsmurf_history, poll_history, history_value.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.history.id IS
'Primary key - unique identifier for history event (auto-increment, sequential)';

COMMENT ON COLUMN perseus.history.history_type_id IS
'Foreign key to history_type table - event type classification (e.g., CREATE, UPDATE, DELETE)';

COMMENT ON COLUMN perseus.history.creator_id IS
'Foreign key to perseus_user table - user who triggered the event';

COMMENT ON COLUMN perseus.history.created_on IS
'Timestamp when event occurred (default: current timestamp)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'history'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'history';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.history CASCADE;

-- ============================================================================
-- END OF history TABLE DDL
-- ============================================================================
