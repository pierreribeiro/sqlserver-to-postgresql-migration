-- ============================================================================
-- Object: goo
-- Type: TABLE
-- Priority: P0
-- Description: Core materials/entities table - central to Perseus material tracking
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/35. perseus.dbo.goo.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/32. perseus.goo.sql
--   Quality Score: 9.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: goo_type, perseus_user, manufacturer, container, workflow_step, recipe, recipe_part
--   Referenced by: material_transition, transition_material, goo_attachment, goo_comment,
--                  goo_history, material_inventory, material_qc, robot_log_read,
--                  robot_log_transfer, submission_entry
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, no implicit conversions
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.goo)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Core entity table with frequent access
--   Indexes: PRIMARY KEY on id, UNIQUE INDEX on uid (required for FKs)
--   Future indexes: goo_type_id, added_by, container_id, workflow_step_id
--   Expected: High-volume table, ensure proper indexing strategy
-- ============================================================================
-- Data Type Decisions:
--   - uid: VARCHAR(50) NOT CITEXT - used as FK reference in material_transition/transition_material
--   - name: VARCHAR(250) NOT CITEXT - frequently used in JOINs and WHERE clauses
--   - description: TEXT - free-text field (CITEXT would be acceptable but TEXT is standard)
--   - catalog_label: VARCHAR(50) NOT CITEXT - indexed/searchable field
--   - added_on/updated_on/inserted_on: TIMESTAMP - changed from clock_timestamp() to CURRENT_TIMESTAMP
--   - received_on: DATE - date-only field
--   - original_volume/original_mass: DOUBLE PRECISION - floating point measurements
--   - project_id: SMALLINT - small integer range
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed VARCHAR/uid columns from CITEXT (performance)
--   2026-01-26 Claude - Changed clock_timestamp() to CURRENT_TIMESTAMP (transaction consistency)
--   2026-01-26 Claude - Added PRIMARY KEY constraint
--   2026-01-26 Claude - Added UNIQUE INDEX on uid column (required for FK references)
--   2026-01-26 Claude - Added table and column comments
--   2026-01-26 Claude - Changed description to TEXT (better practice than CITEXT)
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.goo CASCADE;

-- Create goo table
CREATE TABLE perseus.goo (
    -- Primary key with IDENTITY (auto-increment)
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Material identification
    uid VARCHAR(50) NOT NULL,
    name VARCHAR(250),
    description TEXT,
    catalog_label VARCHAR(50),

    -- Material classification
    goo_type_id INTEGER NOT NULL DEFAULT 8,
    manufacturer_id INTEGER NOT NULL DEFAULT 1,

    -- Ownership and tracking
    added_by INTEGER NOT NULL,
    project_id SMALLINT,

    -- Physical properties
    original_volume DOUBLE PRECISION DEFAULT 0,
    original_mass DOUBLE PRECISION DEFAULT 0,

    -- Location and workflow
    container_id INTEGER,
    workflow_step_id INTEGER,

    -- Recipe linkage
    recipe_id INTEGER,
    recipe_part_id INTEGER,

    -- External system reference
    triton_task_id INTEGER,

    -- Timestamps
    received_on DATE,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inserted_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Primary key constraint
    CONSTRAINT pk_goo PRIMARY KEY (id)
);

-- ============================================================================
-- Critical Index: uid column MUST be unique for FK references
-- ============================================================================

-- UNIQUE index on uid - REQUIRED for material_transition and transition_material FKs
CREATE UNIQUE INDEX idx_goo_uid ON perseus.goo(uid);

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.goo IS
'Core materials/entities table - central to Perseus material tracking system.
Stores all material instances (plasmids, proteins, chemicals, etc.).
Material lineage relationships tracked via material_transition and transition_material tables.
Referenced by: 10+ child tables including material lineage tracking tables.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.goo.id IS
'Primary key - unique identifier for material (auto-increment)';

COMMENT ON COLUMN perseus.goo.uid IS
'Unique identifier string - used as FK reference in material_transition and transition_material.
MUST remain UNIQUE - enforced by idx_goo_uid index.';

COMMENT ON COLUMN perseus.goo.name IS
'Material name/label (e.g., "pUC19 plasmid", "GFP protein")';

COMMENT ON COLUMN perseus.goo.description IS
'Free-text description of material';

COMMENT ON COLUMN perseus.goo.catalog_label IS
'Catalog or inventory label for material';

COMMENT ON COLUMN perseus.goo.goo_type_id IS
'Foreign key to goo_type table - material type classification (default: 8)';

COMMENT ON COLUMN perseus.goo.manufacturer_id IS
'Foreign key to manufacturer table - material supplier (default: 1)';

COMMENT ON COLUMN perseus.goo.added_by IS
'Foreign key to perseus_user table - user who added this material';

COMMENT ON COLUMN perseus.goo.project_id IS
'Project identifier for material assignment';

COMMENT ON COLUMN perseus.goo.original_volume IS
'Original volume of material in liters (default: 0)';

COMMENT ON COLUMN perseus.goo.original_mass IS
'Original mass of material in kilograms (default: 0)';

COMMENT ON COLUMN perseus.goo.container_id IS
'Foreign key to container table - current storage location';

COMMENT ON COLUMN perseus.goo.workflow_step_id IS
'Foreign key to workflow_step table - current workflow status';

COMMENT ON COLUMN perseus.goo.recipe_id IS
'Foreign key to recipe table - recipe used to create this material';

COMMENT ON COLUMN perseus.goo.recipe_part_id IS
'Foreign key to recipe_part table - specific recipe part for this material';

COMMENT ON COLUMN perseus.goo.triton_task_id IS
'External system reference - Triton task identifier';

COMMENT ON COLUMN perseus.goo.received_on IS
'Date when material was received (date only, no time)';

COMMENT ON COLUMN perseus.goo.added_on IS
'Timestamp when material was added to system (default: current timestamp)';

COMMENT ON COLUMN perseus.goo.updated_on IS
'Timestamp when material record was last updated (default: current timestamp)';

COMMENT ON COLUMN perseus.goo.inserted_on IS
'Timestamp when material record was first inserted (default: current timestamp)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'goo'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'goo';

-- Verify unique index on uid
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'perseus' AND tablename = 'goo';

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP INDEX IF EXISTS perseus.idx_goo_uid;
-- DROP TABLE IF EXISTS perseus.goo CASCADE;

-- ============================================================================
-- END OF goo TABLE DDL
-- ============================================================================
