-- ============================================================================
-- Object: unit
-- Type: TABLE
-- Priority: P1 (High - referenced by property, recipe, workflow_step)
-- Description: Units of measure (mL, g, M, etc.)
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/perseus.dbo.unit.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/87. perseus.unit.sql
--   Quality Score: 8.5/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: None (Tier 0)
--   Referenced by: property, recipe, workflow_step, recipe_part
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.unit CASCADE;

-- Create unit table
CREATE TABLE perseus.unit (
    -- Primary key with IDENTITY
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Unit information
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    dimension_id INTEGER,
    factor DOUBLE PRECISION,
    "offset" DOUBLE PRECISION,

    -- Primary key constraint
    CONSTRAINT pk_unit PRIMARY KEY (id)
);

-- ============================================================================
-- Indexes
-- ============================================================================

CREATE INDEX idx_unit_name ON perseus.unit(name);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.unit IS
'Units of measure (mL, g, M, etc.) for material properties and recipes.
Referenced by: property, recipe, workflow_step, recipe_part.
Lookup table with 50-100 rows.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.unit.id IS
'Primary key - unique identifier for unit (auto-increment)';

COMMENT ON COLUMN perseus.unit.name IS
'Unit name (e.g., "mL", "g", "M", "mol", "rpm")';

COMMENT ON COLUMN perseus.unit.description IS
'Unit description or full name';

COMMENT ON COLUMN perseus.unit.dimension_id IS
'Dimension category (e.g., volume, mass, concentration)';

COMMENT ON COLUMN perseus.unit.factor IS
'Conversion factor to base unit';

COMMENT ON COLUMN perseus.unit.offset IS
'Offset for unit conversion (e.g., Celsius to Kelvin)';

-- ============================================================================
-- END OF unit TABLE DDL
-- ============================================================================
