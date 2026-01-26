-- ============================================================================
-- Object: property
-- Type: TABLE
-- Priority: P1
-- Description: Material property definitions (e.g., pH, temperature, concentration)
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/63. perseus.dbo.property.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/58. perseus.property.sql
--   Quality Score: 8.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: unit
--   Referenced by: property_option, smurf_property, goo_property (likely)
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, VARCHAR for indexed columns
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.property)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Lookup/reference table with moderate access frequency
--   Indexes: PRIMARY KEY on id
--   Future indexes: name (for property lookups), unit_id (for FK joins)
--   Expected: Low-volume table (~100-500 rows)
-- ============================================================================
-- Data Type Decisions:
--   - name: VARCHAR(100) NOT CITEXT - property names are standardized identifiers
--   - description: VARCHAR(500) - free-text description (limited length)
--   - unit_id: INTEGER - FK to unit table (nullable for dimensionless properties)
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
DROP TABLE IF EXISTS perseus.property CASCADE;

-- Create property table
CREATE TABLE perseus.property (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Property definition
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),

    -- Unit of measure
    unit_id INTEGER,

    -- Primary key constraint
    CONSTRAINT pk_property PRIMARY KEY (id)
);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.property IS
'Material property definitions (e.g., pH, temperature, concentration, purity).
Defines measurable or observable characteristics of materials.
Properties may have units (via unit_id FK) or be dimensionless (NULL unit_id).
Referenced by: property_option, smurf_property, material property tracking.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.property.id IS
'Primary key - unique identifier for property (auto-increment)';

COMMENT ON COLUMN perseus.property.name IS
'Property name (e.g., "pH", "Temperature", "Concentration", "Purity (%)")';

COMMENT ON COLUMN perseus.property.description IS
'Free-text description of property and measurement guidelines';

COMMENT ON COLUMN perseus.property.unit_id IS
'Foreign key to unit table - unit of measure for property (NULL for dimensionless properties)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'property'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'property';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.property CASCADE;

-- ============================================================================
-- END OF property TABLE DDL
-- ============================================================================
