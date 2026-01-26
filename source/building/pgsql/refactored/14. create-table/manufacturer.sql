-- ============================================================================
-- Object: manufacturer
-- Type: TABLE
-- Priority: P0 (High - many dependencies)
-- Description: Vendor/supplier definitions for materials
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/perseus.dbo.manufacturer.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/48. perseus.manufacturer.sql
--   Quality Score: 8.5/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: None (Tier 0)
--   Referenced by: goo, perseus_user, external_goo_type, workflow, fatsmurf
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types (VARCHAR not CITEXT)
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.manufacturer)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   - Lookup table (10-50 rows)
--   - Frequently joined by goo and perseus_user tables
--   - Index on name recommended for lookups
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed CITEXT to VARCHAR (indexed columns)
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.manufacturer CASCADE;

-- Create manufacturer table
CREATE TABLE perseus.manufacturer (
    -- Primary key with IDENTITY
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Manufacturer information
    name VARCHAR(200) NOT NULL,
    location VARCHAR(200),
    goo_prefix VARCHAR(20),

    -- Primary key constraint
    CONSTRAINT pk_manufacturer PRIMARY KEY (id)
);

-- ============================================================================
-- Indexes
-- ============================================================================

-- Index on name for lookups
CREATE INDEX idx_manufacturer_name ON perseus.manufacturer(name);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.manufacturer IS
'Vendor/supplier definitions for materials in Perseus system.
Referenced by: goo, perseus_user, external_goo_type, workflow, fatsmurf.
Lookup table with 10-50 rows.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.manufacturer.id IS
'Primary key - unique identifier for manufacturer (auto-increment)';

COMMENT ON COLUMN perseus.manufacturer.name IS
'Manufacturer/vendor name (e.g., "Sigma-Aldrich", "Thermo Fisher")';

COMMENT ON COLUMN perseus.manufacturer.location IS
'Physical location or region of manufacturer';

COMMENT ON COLUMN perseus.manufacturer.goo_prefix IS
'Prefix code used for material naming (e.g., "SA-" for Sigma-Aldrich)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'manufacturer'
-- ORDER BY ordinal_position;

-- ============================================================================
-- END OF manufacturer TABLE DDL
-- ============================================================================
