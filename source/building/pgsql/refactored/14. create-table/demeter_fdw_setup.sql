-- ============================================================================
-- Demeter Foreign Data Wrapper (FDW) Setup
-- Priority: P1 (High - seed vial tracking)
-- ============================================================================
-- IMPORTANT: These tables MUST be created as FOREIGN TABLEs, not regular tables.
-- ============================================================================

-- Drop existing tables if they were incorrectly created as local tables
DROP TABLE IF EXISTS demeter.barcodes CASCADE;
DROP TABLE IF EXISTS demeter.seed_vials CASCADE;

-- ============================================================================
-- Foreign Server Setup (if different from Hermes)
-- ============================================================================

-- If Demeter is on a different server:
/*
CREATE SERVER demeter_fdw
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'demeter-db-hostname',
        dbname 'demeter',
        port '5432'
    );

CREATE USER MAPPING FOR perseus_app_user
    SERVER demeter_fdw
    OPTIONS (
        user 'readonly_user',
        password 'REPLACE_WITH_ACTUAL_PASSWORD'
    );
*/

-- ============================================================================
-- demeter.barcodes
-- ============================================================================

CREATE FOREIGN TABLE demeter.barcodes (
    id INTEGER NOT NULL,
    barcode VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id INTEGER,
    created_on TIMESTAMP,
    created_by INTEGER
    -- Additional columns may exist - verify with source table
)
SERVER demeter_fdw
OPTIONS (schema_name 'public', table_name 'barcodes', fetch_size '5000');

COMMENT ON FOREIGN TABLE demeter.barcodes IS
'FOREIGN TABLE: Barcode tracking from Demeter system.
Verify complete column list before production. Updated: 2026-01-26';

-- ============================================================================
-- demeter.seed_vials (26 columns)
-- ============================================================================

CREATE FOREIGN TABLE demeter.seed_vials (
    id INTEGER NOT NULL,
    strain_id INTEGER,
    vial_barcode VARCHAR(100),
    freeze_date DATE,
    location VARCHAR(200),
    box_position VARCHAR(20),
    vial_number INTEGER,
    notes TEXT,
    created_on TIMESTAMP,
    created_by INTEGER,
    is_active BOOLEAN
    -- Additional columns exist (15 more) - verify with source table
)
SERVER demeter_fdw
OPTIONS (schema_name 'public', table_name 'seed_vials', fetch_size '5000');

COMMENT ON FOREIGN TABLE demeter.seed_vials IS
'FOREIGN TABLE: Seed vial inventory from Demeter (26 total columns).
PARTIAL SCHEMA - Complete column list needed for production. Updated: 2026-01-26';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test connectivity:
-- SELECT COUNT(*) FROM demeter.barcodes LIMIT 10;
-- SELECT COUNT(*) FROM demeter.seed_vials LIMIT 10;

-- ============================================================================
-- PRODUCTION NOTES
-- ============================================================================

/*
BEFORE PRODUCTION:

1. Complete column definitions:
   - demeter.barcodes: Verify all columns
   - demeter.seed_vials: Add remaining 15 columns

2. Configure foreign server (if separate from Hermes)

3. Test data synchronization patterns

4. Consider materialized views for frequently accessed data
*/

-- ============================================================================
-- END OF Demeter FDW Setup
-- ============================================================================
