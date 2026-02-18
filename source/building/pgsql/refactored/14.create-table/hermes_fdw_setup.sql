-- ============================================================================
-- Hermes Foreign Data Wrapper (FDW) Server Configuration
-- Priority: P1 (High - external fermentation data)
-- ============================================================================
-- This file configures the FDW server connection.
-- Individual table definitions are in separate files:
--   hermes_run.sql (90 columns)
--   hermes_run_condition.sql (4 columns)
--   hermes_run_condition_option.sql (4 columns)
--   hermes_run_condition_value.sql (5 columns)
--   hermes_run_master_condition.sql (10 columns)
--   hermes_run_master_condition_type.sql (3 columns)
-- ============================================================================

-- Step 1: Create postgres_fdw extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Step 2: Create hermes schema
CREATE SCHEMA IF NOT EXISTS hermes;

-- Step 3: Create foreign server (REPLACE with actual connection details)
-- CREATE SERVER hermes_server
--     FOREIGN DATA WRAPPER postgres_fdw
--     OPTIONS (
--         host 'hermes-db-hostname',
--         dbname 'hermes',
--         port '5432'
--     );

-- Step 4: Create user mapping (REPLACE with actual credentials)
-- CREATE USER MAPPING FOR perseus_app_user
--     SERVER hermes_server
--     OPTIONS (
--         user 'readonly_user',
--         password 'REPLACE_WITH_ACTUAL_PASSWORD'
--     );

-- Step 5: Grant usage on foreign server
-- GRANT USAGE ON FOREIGN SERVER hermes_server TO perseus_app_user;

-- ============================================================================
-- Deployment Order:
--   1. Run this file first (server configuration)
--   2. Then run individual table files in any order
-- ============================================================================
