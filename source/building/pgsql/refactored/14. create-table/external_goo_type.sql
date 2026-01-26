-- ============================================================================
-- Object: external_goo_type
-- Type: TABLE
-- Priority: P2
-- Description: Maps external vendor material labels to internal goo_types
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/22. perseus.dbo.external_goo_type.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/20. perseus.external_goo_type.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: goo_type, manufacturer
--   Referenced by: Material import/integration workflows
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, VARCHAR for indexed columns
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.external_goo_type)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Lookup table for material import/integration
--   Indexes: PRIMARY KEY on id
--   Future indexes: (manufacturer_id, external_label) for lookups, goo_type_id for FK joins
--   Expected: Low-volume table (~100-1,000 rows)
-- ============================================================================
-- Data Type Decisions:
--   - external_label: VARCHAR(250) NOT CITEXT - vendor-specific material labels (case-sensitive)
--   - goo_type_id: INTEGER NOT NULL - maps to internal material type
--   - manufacturer_id: INTEGER NOT NULL - vendor/supplier identifier
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
DROP TABLE IF EXISTS perseus.external_goo_type CASCADE;

-- Create external_goo_type table
CREATE TABLE perseus.external_goo_type (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Internal material type mapping
    goo_type_id INTEGER NOT NULL,

    -- External vendor information
    external_label VARCHAR(250) NOT NULL,
    manufacturer_id INTEGER NOT NULL,

    -- Primary key constraint
    CONSTRAINT pk_external_goo_type PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.external_goo_type IS
'Maps external vendor material labels to internal goo_type classifications.
Enables automatic material type recognition during import/integration.
Example: Vendor catalog "E. coli DH5α" → goo_type "Bacterial Strain".
Referenced by: Material import workflows, vendor integration processes.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.external_goo_type.id IS
'Primary key - unique identifier for external mapping (auto-increment)';

COMMENT ON COLUMN perseus.external_goo_type.goo_type_id IS
'Foreign key to goo_type table - internal material type classification';

COMMENT ON COLUMN perseus.external_goo_type.external_label IS
'External vendor material label/catalog name (e.g., "pUC19 Vector", "E. coli DH5α")';

COMMENT ON COLUMN perseus.external_goo_type.manufacturer_id IS
'Foreign key to manufacturer table - vendor/supplier identifier';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'external_goo_type'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'external_goo_type';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.external_goo_type CASCADE;

-- ============================================================================
-- END OF external_goo_type TABLE DDL
-- ============================================================================
