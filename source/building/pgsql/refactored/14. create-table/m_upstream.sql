-- ============================================================================
-- Object: m_upstream
-- Type: TABLE
-- Priority: P0 (CRITICAL - Material lineage performance)
-- Description: Cached upstream lineage graph for material tracking
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/perseus.dbo.m_upstream.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/46. perseus.m_upstream.sql
--   Quality Score: 9.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: None (Tier 0 - populated by mcgetupstream stored procedure)
--   Referenced by: mcgetupstream, mcgetupstreambylist functions
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types (VARCHAR not CITEXT)
--   [✓] III. Set-Based - Table structure optimized for set-based lineage queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.m_upstream)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   CRITICAL PERFORMANCE TABLE:
--   - Cached materialized lineage paths (100,000+ rows)
--   - Enables fast ancestor queries without recursive CTEs
--   - Composite index on (start_point, end_point) is MANDATORY
--   - Index on (end_point, level) for reverse lookups
--   - Path column stores serialized lineage path
--   - Populated by mcgetupstream stored procedure
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed CITEXT to VARCHAR (high-performance joins)
--   2026-01-26 Claude - Added composite PRIMARY KEY on (start_point, end_point)
--   2026-01-26 Claude - Added performance indexes
--   2026-01-26 Claude - Added table and column comments
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.m_upstream CASCADE;

-- Create m_upstream table
CREATE TABLE perseus.m_upstream (
    -- Material identifiers (uid values from goo/fatsmurf)
    start_point VARCHAR(50) NOT NULL,
    end_point VARCHAR(50) NOT NULL,

    -- Lineage metadata
    path VARCHAR(4000) NOT NULL,
    level INTEGER NOT NULL,

    -- Composite primary key
    CONSTRAINT pk_m_upstream PRIMARY KEY (start_point, end_point)
);

-- ============================================================================
-- CRITICAL Performance Indexes
-- ============================================================================

-- Index for reverse lookups (finding all ancestors of a given endpoint)
CREATE INDEX idx_m_upstream_end_level ON perseus.m_upstream(end_point, level);

-- Index on level for depth-based queries
CREATE INDEX idx_m_upstream_level ON perseus.m_upstream(level);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.m_upstream IS
'CRITICAL PERFORMANCE TABLE: Cached upstream lineage graph for material tracking.
Stores materialized paths from start_point (descendant) to end_point (ancestor).
Enables fast ancestor queries without recursive CTEs (100,000+ rows).
Populated by mcgetupstream stored procedure.
IMPORTANT: Composite PK (start_point, end_point) prevents duplicates.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.m_upstream.start_point IS
'Starting material UID (descendant) - part of composite PK';

COMMENT ON COLUMN perseus.m_upstream.end_point IS
'Ending material UID (ancestor) - part of composite PK';

COMMENT ON COLUMN perseus.m_upstream.path IS
'Serialized lineage path from start_point to end_point (VARCHAR 4000)';

COMMENT ON COLUMN perseus.m_upstream.level IS
'Depth level in lineage tree (0 = self, 1 = immediate parent, etc.)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'm_upstream'
-- ORDER BY ordinal_position;

-- Verify indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'perseus' AND tablename = 'm_upstream';

-- ============================================================================
-- Usage Example
-- ============================================================================

-- Find all ancestors of a material (depth 1-5):
-- SELECT end_point, level, path
-- FROM perseus.m_upstream
-- WHERE start_point = 'M123456'
--   AND level BETWEEN 1 AND 5
-- ORDER BY level;

-- ============================================================================
-- END OF m_upstream TABLE DDL
-- ============================================================================
