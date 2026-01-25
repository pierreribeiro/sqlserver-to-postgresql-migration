-- Perseus Database Migration - PostgreSQL Initialization Script
-- This script runs automatically when the container is first created
-- It sets up extensions, schemas, and basic configuration

-- =============================================================================
-- 1. Enable Required Extensions
-- =============================================================================

-- Create extensions in the public schema first
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA public;       -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" SCHEMA public; -- Query performance monitoring
CREATE EXTENSION IF NOT EXISTS "btree_gist" SCHEMA public;      -- Additional index types
CREATE EXTENSION IF NOT EXISTS "pg_trgm" SCHEMA public;         -- Trigram matching for text search

-- Note: postgres_fdw, pgAgent, pg_cron will be installed manually as needed
-- These require superuser privileges and are environment-specific

-- =============================================================================
-- 2. Create Schemas
-- =============================================================================

-- Application schema (main Perseus schema)
CREATE SCHEMA IF NOT EXISTS perseus AUTHORIZATION perseus_admin;

-- Testing schemas
CREATE SCHEMA IF NOT EXISTS perseus_test AUTHORIZATION perseus_admin;
CREATE SCHEMA IF NOT EXISTS fixtures AUTHORIZATION perseus_admin;

-- =============================================================================
-- 3. Set Search Path
-- =============================================================================

-- Set default search path for perseus_admin user
ALTER ROLE perseus_admin SET search_path TO perseus, public;

-- =============================================================================
-- 4. Grant Permissions
-- =============================================================================

-- Grant usage on schemas
GRANT USAGE ON SCHEMA perseus TO PUBLIC;
GRANT USAGE ON SCHEMA perseus_test TO PUBLIC;
GRANT USAGE ON SCHEMA fixtures TO PUBLIC;

-- Grant permissions on public schema extensions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO perseus_admin;

-- =============================================================================
-- 5. Configure Database Settings
-- =============================================================================

-- Set timezone
ALTER DATABASE perseus_dev SET timezone TO 'America/Sao_Paulo';

-- Enable detailed logging for DDL operations
ALTER DATABASE perseus_dev SET log_statement TO 'ddl';

-- Set statement timeout (30 minutes for migration operations)
ALTER DATABASE perseus_dev SET statement_timeout TO '1800000';

-- Enable parallel query execution
ALTER DATABASE perseus_dev SET max_parallel_workers_per_gather TO 4;

-- =============================================================================
-- 6. Create Audit Tables (Optional - for tracking migrations)
-- =============================================================================

CREATE TABLE IF NOT EXISTS perseus.migration_log (
    id SERIAL PRIMARY KEY,
    migration_phase VARCHAR(100) NOT NULL,
    object_type VARCHAR(50) NOT NULL,
    object_name VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('started', 'completed', 'failed', 'rolled_back')),
    quality_score NUMERIC(4,2),
    performance_delta NUMERIC(6,2),
    error_message TEXT,
    executed_by VARCHAR(100) DEFAULT CURRENT_USER,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_duration_ms INTEGER
);

CREATE INDEX idx_migration_log_object ON perseus.migration_log(object_type, object_name);
CREATE INDEX idx_migration_log_status ON perseus.migration_log(status);
CREATE INDEX idx_migration_log_executed_at ON perseus.migration_log(executed_at DESC);

-- =============================================================================
-- 7. Create Helper Functions
-- =============================================================================

-- Function to check if object exists (useful for idempotent migrations)
CREATE OR REPLACE FUNCTION perseus.object_exists(
    p_schema_name TEXT,
    p_object_name TEXT,
    p_object_type TEXT DEFAULT 'table'
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    CASE LOWER(p_object_type)
        WHEN 'table' THEN
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_schema = p_schema_name
                  AND table_name = p_object_name
            ) INTO v_exists;
        WHEN 'view' THEN
            SELECT EXISTS (
                SELECT 1 FROM information_schema.views
                WHERE table_schema = p_schema_name
                  AND table_name = p_object_name
            ) INTO v_exists;
        WHEN 'function' THEN
            SELECT EXISTS (
                SELECT 1 FROM information_schema.routines
                WHERE routine_schema = p_schema_name
                  AND routine_name = p_object_name
                  AND routine_type = 'FUNCTION'
            ) INTO v_exists;
        WHEN 'procedure' THEN
            SELECT EXISTS (
                SELECT 1 FROM information_schema.routines
                WHERE routine_schema = p_schema_name
                  AND routine_name = p_object_name
                  AND routine_type = 'PROCEDURE'
            ) INTO v_exists;
        ELSE
            RAISE EXCEPTION 'Unsupported object type: %', p_object_type;
    END CASE;

    RETURN v_exists;
END;
$$;

-- =============================================================================
-- 8. Verify Setup
-- =============================================================================

DO $$
DECLARE
    v_version TEXT;
    v_encoding TEXT;
    v_collate TEXT;
    v_ctype TEXT;
BEGIN
    -- Get PostgreSQL version
    SELECT version() INTO v_version;
    RAISE NOTICE 'PostgreSQL Version: %', v_version;

    -- Get database encoding settings
    SELECT pg_encoding_to_char(encoding), datcollate, datctype
    INTO v_encoding, v_collate, v_ctype
    FROM pg_database
    WHERE datname = current_database();

    RAISE NOTICE 'Database Encoding: %', v_encoding;
    RAISE NOTICE 'LC_COLLATE: %', v_collate;
    RAISE NOTICE 'LC_CTYPE: %', v_ctype;

    -- Verify UTF-8 encoding
    IF v_encoding != 'UTF8' THEN
        RAISE WARNING 'Database encoding is not UTF-8! Expected: UTF8, Found: %', v_encoding;
    ELSE
        RAISE NOTICE 'UTF-8 encoding verified ✓';
    END IF;

    -- List installed extensions
    RAISE NOTICE 'Installed extensions:';
    FOR v_version IN
        SELECT extname || ' ' || extversion AS ext
        FROM pg_extension
        ORDER BY extname
    LOOP
        RAISE NOTICE '  - %', v_version;
    END LOOP;

    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Perseus PostgreSQL Development Environment initialized successfully!';
    RAISE NOTICE '=================================================================';
END;
$$;
