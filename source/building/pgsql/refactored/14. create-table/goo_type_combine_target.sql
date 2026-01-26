-- ============================================================================
-- Object: goo_type_combine_target
-- Type: TABLE
-- Priority: P1
-- Description: Defines target material types for combination operations
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/43. perseus.dbo.goo_type_combine_target.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/39. perseus.goo_type_combine_target.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: goo_type
--   Referenced by: Material combination workflows, goo_type_combine_component
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, INTEGER for FKs and sort order
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.goo_type_combine_target)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Configuration table for material combination rules
--   Indexes: PRIMARY KEY on id
--   Future indexes: goo_type_id (for FK joins), sort_order (for display ordering)
--   Expected: Low-volume table (~50-200 rows)
-- ============================================================================
-- Data Type Decisions:
--   - goo_type_id: INTEGER NOT NULL - material type that can be a combination target
--   - sort_order: INTEGER NOT NULL - display/priority order for combinations
-- ============================================================================
-- Business Logic:
--   Defines which material types can be created as targets of combination operations.
--   Example: "Plasmid Mix" goo_type can be a target for combining individual plasmids.
--   Works with goo_type_combine_component to define complete combination rules.
--   sort_order determines priority/display order in UI.
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.goo_type_combine_target CASCADE;

-- Create goo_type_combine_target table
CREATE TABLE perseus.goo_type_combine_target (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Target material type definition
    goo_type_id INTEGER NOT NULL,

    -- Display/priority ordering
    sort_order INTEGER NOT NULL,

    -- Primary key constraint
    CONSTRAINT pk_goo_type_combine_target PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.goo_type_combine_target IS
'Defines target material types for combination operations.
Specifies which goo_types can be created as results of combining multiple materials.
Example: "Plasmid Mix" can be a target for combining individual plasmids.
Works with goo_type_combine_component to define complete combination rules:
- This table = what can be created (targets)
- goo_type_combine_component = what can be combined (components)
Referenced by: Material combination workflows, UI combination wizards.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.goo_type_combine_target.id IS
'Primary key - unique identifier for combination target definition (auto-increment)';

COMMENT ON COLUMN perseus.goo_type_combine_target.goo_type_id IS
'Foreign key to goo_type table - material type that can be created as combination target';

COMMENT ON COLUMN perseus.goo_type_combine_target.sort_order IS
'Display/priority order for UI presentation (lower = higher priority)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'goo_type_combine_target'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'goo_type_combine_target';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.goo_type_combine_target CASCADE;

-- ============================================================================
-- END OF goo_type_combine_target TABLE DDL
-- ============================================================================
