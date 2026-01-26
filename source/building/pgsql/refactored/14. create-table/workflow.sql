-- ============================================================================
-- Object: workflow
-- Type: TABLE
-- Priority: P1
-- Description: Workflow/process definitions for material production and tracking
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/88. perseus.dbo.workflow.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/83. perseus.workflow.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: perseus_user, manufacturer
--   Referenced by: workflow_step, workflow_section, goo, recipe, fatsmurf
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, VARCHAR for indexed columns, BOOLEAN for flags
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.workflow)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Reference table with moderate access frequency
--   Indexes: PRIMARY KEY on id
--   Future indexes: manufacturer_id (for FK joins), disabled (for active workflow queries)
--   Expected: Low-volume table (~50-200 rows)
-- ============================================================================
-- Data Type Decisions:
--   - name: VARCHAR(150) NOT CITEXT - workflow names are standardized
--   - description: VARCHAR(1000) - free-text description
--   - category: VARCHAR(150) - workflow categorization
--   - disabled: BOOLEAN NOT INTEGER - flag for active/inactive workflows
--   - added_by: INTEGER with DEFAULT 23 - user ID (preserved from SQL Server)
--   - added_on: TIMESTAMP with CURRENT_TIMESTAMP - creation timestamp
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed VARCHAR columns from CITEXT to VARCHAR
--   2026-01-26 Claude - Changed disabled from INTEGER to BOOLEAN
--   2026-01-26 Claude - Changed getdate() to CURRENT_TIMESTAMP
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.workflow CASCADE;

-- Create workflow table
CREATE TABLE perseus.workflow (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Workflow definition
    name VARCHAR(150) NOT NULL,
    description VARCHAR(1000),
    category VARCHAR(150),

    -- Ownership and status
    added_by INTEGER NOT NULL DEFAULT 23,
    manufacturer_id INTEGER NOT NULL,
    disabled BOOLEAN NOT NULL DEFAULT FALSE,

    -- Timestamps
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Primary key constraint
    CONSTRAINT pk_workflow PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.workflow IS
'Workflow/process definitions for material production and tracking.
Defines multi-step processes for material handling, testing, and quality control.
Each workflow consists of sections and steps (defined in workflow_section and workflow_step tables).
Referenced by: workflow_step, workflow_section, goo, recipe, fatsmurf.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.workflow.id IS
'Primary key - unique identifier for workflow (auto-increment)';

COMMENT ON COLUMN perseus.workflow.name IS
'Workflow name (e.g., "Protein Purification", "Plasmid Prep QC")';

COMMENT ON COLUMN perseus.workflow.description IS
'Free-text description of workflow purpose and steps';

COMMENT ON COLUMN perseus.workflow.category IS
'Workflow category for grouping (e.g., "Production", "QC", "Storage")';

COMMENT ON COLUMN perseus.workflow.added_by IS
'Foreign key to perseus_user table - user who created workflow (default: 23)';

COMMENT ON COLUMN perseus.workflow.manufacturer_id IS
'Foreign key to manufacturer table - organization/vendor associated with workflow';

COMMENT ON COLUMN perseus.workflow.disabled IS
'Workflow status flag - TRUE if workflow is inactive/disabled, FALSE if active (default: FALSE)';

COMMENT ON COLUMN perseus.workflow.added_on IS
'Timestamp when workflow was created (default: current timestamp)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'workflow'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'workflow';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.workflow CASCADE;

-- ============================================================================
-- END OF workflow TABLE DDL
-- ============================================================================
