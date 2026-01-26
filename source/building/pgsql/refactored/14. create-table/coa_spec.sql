-- ============================================================================
-- Object: coa_spec
-- Type: TABLE
-- Priority: P2
-- Description: Certificate of Analysis specifications - defines test limits
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/14. perseus.dbo.coa_spec.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/11. perseus.coa_spec.sql
--   Quality Score: 7.5/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: coa, property
--   Referenced by: None
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.coa_spec CASCADE;

-- Create coa_spec table
CREATE TABLE perseus.coa_spec (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Foreign keys
    coa_id INTEGER NOT NULL,
    property_id INTEGER NOT NULL,

    -- Specification bounds
    upper_bound DOUBLE PRECISION,
    lower_bound DOUBLE PRECISION,
    equal_bound VARCHAR(150),
    upper_equal_bound DOUBLE PRECISION,
    lower_equal_bound DOUBLE PRECISION,
    result_precision INTEGER DEFAULT 0,

    -- Primary key constraint
    CONSTRAINT pk_coa_spec PRIMARY KEY (id)
);

-- Index on coa_id for COA lookups
CREATE INDEX idx_coa_spec_coa_id ON perseus.coa_spec(coa_id);

-- Index on property_id for property lookups
CREATE INDEX idx_coa_spec_property_id ON perseus.coa_spec(property_id);

-- Table and column comments
COMMENT ON TABLE perseus.coa_spec IS
'Certificate of Analysis specifications - defines test limits and acceptance criteria for material properties.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.coa_spec.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.coa_spec.coa_id IS 'Foreign key to coa table';
COMMENT ON COLUMN perseus.coa_spec.property_id IS 'Foreign key to property table';
COMMENT ON COLUMN perseus.coa_spec.upper_bound IS 'Upper limit for property value';
COMMENT ON COLUMN perseus.coa_spec.lower_bound IS 'Lower limit for property value';
COMMENT ON COLUMN perseus.coa_spec.equal_bound IS 'Exact value requirement (text)';
COMMENT ON COLUMN perseus.coa_spec.upper_equal_bound IS 'Upper limit inclusive (<=)';
COMMENT ON COLUMN perseus.coa_spec.lower_equal_bound IS 'Lower limit inclusive (>=)';
COMMENT ON COLUMN perseus.coa_spec.result_precision IS 'Decimal places for result display (default: 0)';

-- ============================================================================
-- END OF coa_spec TABLE DDL
-- ============================================================================
