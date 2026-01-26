-- ============================================================================
-- Object: goo_type
-- Type: TABLE
-- Priority: P0
-- Description: Material type definitions with hierarchical nested set model
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/41. perseus.dbo.goo_type.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/38. perseus.goo_type.sql
--   Quality Score: 9.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: NONE (Tier 0 base table)
--   Referenced by: external_goo_type, goo_type_combine_target, coa, smurf_goo_type,
--                  goo_type_combine_component, workflow_step, recipe, goo,
--                  material_inventory_threshold
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, no implicit conversions
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.goo_type)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Core lookup table, minimal performance impact
--   Indexes: PRIMARY KEY on id, future indexes on name, scope_id, left_id/right_id
--   Expected: Sub-millisecond lookups by id
-- ============================================================================
-- Data Type Decisions:
--   - name: VARCHAR(128) NOT CITEXT - frequently used in JOINs and WHERE clauses
--   - scope_id: VARCHAR(50) NOT CITEXT - used as FK reference
--   - color: CITEXT - free-text field for display
--   - disabled: BOOLEAN NOT INTEGER - true boolean flag
--   - casrn: CITEXT - Chemical registry number (free-text)
--   - iupac: CITEXT - Chemical name (free-text)
--   - abbreviation: CITEXT - Free-text abbreviation
--   - left_id/right_id: INTEGER - nested set model for hierarchy
--   - density_kg_l: DOUBLE PRECISION - floating point density
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed VARCHAR columns from CITEXT (performance)
--   2026-01-26 Claude - Changed disabled from INTEGER to BOOLEAN
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.goo_type CASCADE;

-- Create goo_type table
CREATE TABLE perseus.goo_type (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Material type identification
    name VARCHAR(128) NOT NULL,
    color CITEXT,

    -- Nested set model columns for hierarchical queries
    left_id INTEGER NOT NULL,
    right_id INTEGER NOT NULL,
    depth INTEGER NOT NULL DEFAULT 0,

    -- Scope/namespace identifier
    scope_id VARCHAR(50) NOT NULL,

    -- Status flag
    disabled BOOLEAN NOT NULL DEFAULT FALSE,

    -- Chemical identifiers (free-text fields)
    casrn CITEXT,
    iupac CITEXT,
    abbreviation CITEXT,

    -- Physical properties
    density_kg_l DOUBLE PRECISION,

    -- Primary key constraint
    CONSTRAINT pk_goo_type PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.goo_type IS
'Material type definitions using nested set model for hierarchical material taxonomy.
Core table for material classification system.
Referenced by: goo, external_goo_type, goo_type_combine_target, coa, workflow_step, recipe.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.goo_type.id IS
'Primary key - unique identifier for material type (auto-increment)';

COMMENT ON COLUMN perseus.goo_type.name IS
'Material type name (e.g., "Plasmid DNA", "Protein", "Chemical")';

COMMENT ON COLUMN perseus.goo_type.color IS
'Display color for UI rendering (hex code or color name)';

COMMENT ON COLUMN perseus.goo_type.left_id IS
'Nested set left boundary - used for hierarchical queries';

COMMENT ON COLUMN perseus.goo_type.right_id IS
'Nested set right boundary - used for hierarchical queries';

COMMENT ON COLUMN perseus.goo_type.depth IS
'Depth in hierarchy (0 = root level)';

COMMENT ON COLUMN perseus.goo_type.scope_id IS
'Namespace/scope identifier for material type classification';

COMMENT ON COLUMN perseus.goo_type.disabled IS
'Flag indicating if material type is disabled (TRUE = disabled)';

COMMENT ON COLUMN perseus.goo_type.casrn IS
'Chemical Abstracts Service Registry Number (for chemical materials)';

COMMENT ON COLUMN perseus.goo_type.iupac IS
'IUPAC chemical name (International Union of Pure and Applied Chemistry)';

COMMENT ON COLUMN perseus.goo_type.abbreviation IS
'Abbreviated material type name for compact display';

COMMENT ON COLUMN perseus.goo_type.density_kg_l IS
'Material density in kilograms per liter (kg/L)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'goo_type'
-- ORDER BY ordinal_position;

-- Verify constraint
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'goo_type';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.goo_type CASCADE;

-- ============================================================================
-- END OF goo_type TABLE DDL
-- ============================================================================
