-- ============================================================================
-- Object: coa
-- Type: TABLE
-- Priority: P2
-- Description: Certificate of Analysis templates for material types
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/13. perseus.dbo.coa.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/10. perseus.coa.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: goo_type
--   Referenced by: coa_spec, material quality certifications
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, VARCHAR for indexed columns
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.coa)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Reference table with low access frequency
--   Indexes: PRIMARY KEY on id
--   Future indexes: goo_type_id (for FK joins), name (for lookups)
--   Expected: Low-volume table (~10-100 rows)
-- ============================================================================
-- Data Type Decisions:
--   - name: VARCHAR(150) NOT CITEXT - COA template names are standardized
--   - goo_type_id: INTEGER NOT NULL - each COA template linked to material type
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
DROP TABLE IF EXISTS perseus.coa CASCADE;

-- Create coa table
CREATE TABLE perseus.coa (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- COA template definition
    name VARCHAR(150) NOT NULL,

    -- Material type linkage
    goo_type_id INTEGER NOT NULL,

    -- Primary key constraint
    CONSTRAINT pk_coa PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.coa IS
'Certificate of Analysis (COA) templates for material types.
Defines quality certification templates applicable to specific material types.
Each COA template specifies required quality specifications (linked via coa_spec table).
Referenced by: coa_spec (specification details), material quality workflows.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.coa.id IS
'Primary key - unique identifier for COA template (auto-increment)';

COMMENT ON COLUMN perseus.coa.name IS
'COA template name (e.g., "Protein Purity COA", "Plasmid QC Certificate")';

COMMENT ON COLUMN perseus.coa.goo_type_id IS
'Foreign key to goo_type table - material type this COA applies to';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'coa'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'coa';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.coa CASCADE;

-- ============================================================================
-- END OF coa TABLE DDL
-- ============================================================================
