-- ============================================================================
-- Demeter Foreign Data Wrapper (FDW) Server Configuration
-- Priority: P1 (High - seed vial tracking)
-- ============================================================================
-- This file configures the FDW server connection.
-- Individual table definitions are in separate files:
--   demeter_barcodes.sql (3 columns)
--   demeter_seed_vials.sql (22 columns)
-- ============================================================================

-- Step 1: Create postgres_fdw extension (if not already done by hermes setup)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Step 2: Create demeter schema
CREATE SCHEMA IF NOT EXISTS demeter;

-- Step 3: Create foreign server (REPLACE with actual connection details)
-- CREATE SERVER demeter_server
--     FOREIGN DATA WRAPPER postgres_fdw
--     OPTIONS (
--         host 'demeter-db-hostname',
--         dbname 'demeter',
--         port '5432'
--     );

-- Step 4: Create user mapping (REPLACE with actual credentials)
-- CREATE USER MAPPING FOR perseus_app_user
--     SERVER demeter_server
--     OPTIONS (
--         user 'readonly_user',
--         password 'REPLACE_WITH_ACTUAL_PASSWORD'
--     );

-- Step 5: Grant usage on foreign server
-- GRANT USAGE ON FOREIGN SERVER demeter_server TO perseus_app_user;

-- ============================================================================
-- Deployment Order:
--   1. Run this file first (server configuration)
--   2. Then run individual table files in any order
-- ============================================================================
