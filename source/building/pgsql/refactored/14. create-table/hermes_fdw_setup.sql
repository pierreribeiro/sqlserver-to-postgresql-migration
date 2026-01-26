-- ============================================================================
-- Hermes Foreign Data Wrapper (FDW) Setup
-- Priority: P1 (High - external fermentation data)
-- ============================================================================
-- IMPORTANT: These tables MUST be created as FOREIGN TABLEs, not regular tables.
-- The AWS SCT incorrectly created them as local tables with IDENTITY columns.
-- ============================================================================
-- Prerequisites:
--   1. postgres_fdw extension must be installed
--   2. Foreign server 'hermes_fdw' must be configured
--   3. User mapping must be created
-- ============================================================================

-- Step 1: Create postgres_fdw extension (if not exists)
-- CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Step 2: Create foreign server (REPLACE with actual connection details)
/*
CREATE SERVER hermes_fdw
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'hermes-db-hostname',
        dbname 'hermes',
        port '5432'
    );
*/

-- Step 3: Create user mapping (REPLACE with actual credentials)
/*
CREATE USER MAPPING FOR perseus_app_user
    SERVER hermes_fdw
    OPTIONS (
        user 'readonly_user',
        password 'REPLACE_WITH_ACTUAL_PASSWORD'
    );
*/

-- Step 4: Grant usage on foreign server
-- GRANT USAGE ON FOREIGN SERVER hermes_fdw TO perseus_app_user;

-- ============================================================================
-- Foreign Table Definitions
-- ============================================================================

-- Drop existing tables if they were incorrectly created as local tables
DROP TABLE IF EXISTS hermes.run CASCADE;
DROP TABLE IF EXISTS hermes.run_condition CASCADE;
DROP TABLE IF EXISTS hermes.run_condition_option CASCADE;
DROP TABLE IF EXISTS hermes.run_condition_value CASCADE;
DROP TABLE IF EXISTS hermes.run_master_condition CASCADE;
DROP TABLE IF EXISTS hermes.run_master_condition_type CASCADE;

-- ============================================================================
-- hermes.run (94 columns)
-- SIMPLIFIED SCHEMA - Full column list needed for production
-- ============================================================================

CREATE FOREIGN TABLE hermes.run (
    id INTEGER NOT NULL,
    experiment_id INTEGER,
    local_id INTEGER,
    description TEXT,
    strain VARCHAR(30) NOT NULL,
    start_time TIMESTAMP,
    created_on TIMESTAMP,
    updated_on TIMESTAMP
    -- NOTE: 86 additional columns exist in source table
    -- Full schema must be defined before production use
    -- See: source/original/pgsql-aws-sct-converted/14. create-table/95. perseus_hermes.run.sql
)
SERVER hermes_fdw
OPTIONS (schema_name 'public', table_name 'run', fetch_size '1000');

COMMENT ON FOREIGN TABLE hermes.run IS
'FOREIGN TABLE: Fermentation run data from Hermes database (94 total columns).
CRITICAL: This is a SIMPLIFIED schema with only 8 columns defined.
PRODUCTION DEPLOYMENT requires full column list from source table.
Fetch size: 1000 rows per batch for performance. Updated: 2026-01-26';

-- ============================================================================
-- hermes.run_condition (3 columns)
-- ============================================================================

CREATE FOREIGN TABLE hermes.run_condition (
    run_id INTEGER NOT NULL,
    master_condition_id INTEGER NOT NULL,
    option_id INTEGER
)
SERVER hermes_fdw
OPTIONS (schema_name 'public', table_name 'run_condition', fetch_size '5000');

COMMENT ON FOREIGN TABLE hermes.run_condition IS
'FOREIGN TABLE: Run condition mappings from Hermes. Updated: 2026-01-26';

-- ============================================================================
-- hermes.run_condition_option (3 columns)
-- ============================================================================

CREATE FOREIGN TABLE hermes.run_condition_option (
    id INTEGER NOT NULL,
    master_condition_id INTEGER NOT NULL,
    label VARCHAR(100) NOT NULL
)
SERVER hermes_fdw
OPTIONS (schema_name 'public', table_name 'run_condition_option', fetch_size '5000');

COMMENT ON FOREIGN TABLE hermes.run_condition_option IS
'FOREIGN TABLE: Run condition options from Hermes. Updated: 2026-01-26';

-- ============================================================================
-- hermes.run_condition_value (3 columns)
-- ============================================================================

CREATE FOREIGN TABLE hermes.run_condition_value (
    run_id INTEGER NOT NULL,
    master_condition_id INTEGER NOT NULL,
    value VARCHAR(100)
)
SERVER hermes_fdw
OPTIONS (schema_name 'public', table_name 'run_condition_value', fetch_size '5000');

COMMENT ON FOREIGN TABLE hermes.run_condition_value IS
'FOREIGN TABLE: Run condition values from Hermes. Updated: 2026-01-26';

-- ============================================================================
-- hermes.run_master_condition (6 columns)
-- ============================================================================

CREATE FOREIGN TABLE hermes.run_master_condition (
    id INTEGER NOT NULL,
    label VARCHAR(100) NOT NULL,
    type_id INTEGER NOT NULL,
    display_order INTEGER,
    is_active BOOLEAN,
    description TEXT
)
SERVER hermes_fdw
OPTIONS (schema_name 'public', table_name 'run_master_condition', fetch_size '5000');

COMMENT ON FOREIGN TABLE hermes.run_master_condition IS
'FOREIGN TABLE: Master condition definitions from Hermes. Updated: 2026-01-26';

-- ============================================================================
-- hermes.run_master_condition_type (2 columns)
-- ============================================================================

CREATE FOREIGN TABLE hermes.run_master_condition_type (
    id INTEGER NOT NULL,
    label VARCHAR(100) NOT NULL
)
SERVER hermes_fdw
OPTIONS (schema_name 'public', table_name 'run_master_condition_type', fetch_size '5000');

COMMENT ON FOREIGN TABLE hermes.run_master_condition_type IS
'FOREIGN TABLE: Master condition type lookup from Hermes. Updated: 2026-01-26';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Verify foreign server exists:
-- SELECT * FROM pg_foreign_server WHERE srvname = 'hermes_fdw';

-- Verify user mapping:
-- SELECT * FROM pg_user_mappings WHERE srvname = 'hermes_fdw';

-- Test connectivity:
-- SELECT COUNT(*) FROM hermes.run LIMIT 10;

-- ============================================================================
-- CRITICAL PRODUCTION NOTES
-- ============================================================================

/*
BEFORE PRODUCTION DEPLOYMENT:

1. Complete hermes.run column definition (94 columns total)
   - Review source/original/pgsql-aws-sct-converted/14. create-table/95. perseus_hermes.run.sql
   - Add all 86 missing columns

2. Configure actual foreign server connection:
   - Replace placeholder hostname with actual Hermes DB server
   - Use secure credential management (not hardcoded passwords)
   - Consider using SSL/TLS for connection

3. Performance tuning:
   - Adjust fetch_size based on network latency and row size
   - Create local materialized views for frequently accessed data
   - Monitor query performance and add WHERE clause pushdown

4. Security:
   - Use read-only database user for foreign server
   - Restrict schema access to necessary tables only
   - Audit foreign table access patterns

5. Testing:
   - Verify all columns map correctly to source table
   - Test data type compatibility
   - Validate NULL handling
   - Performance benchmark vs direct queries
*/

-- ============================================================================
-- END OF Hermes FDW Setup
-- ============================================================================
