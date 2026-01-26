-- ============================================================================
-- Object: transition_material
-- Type: TABLE
-- Priority: P0
-- Description: Material lineage graph - transition to product material edges
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/86. perseus.dbo.transition_material.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/86. perseus.transition_material.sql
--   Quality Score: 9.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: fatsmurf (uid column), goo (uid column)
--   Referenced by: translated view (materialized), mcgetupstream, mcgetdownstream functions
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, no implicit conversions
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.transition_material)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Critical for material lineage queries
--   Indexes: PRIMARY KEY on (transition_id, material_id), future indexes on each column
--   Expected: High-volume table with frequent joins, ensure proper indexing
-- ============================================================================
-- Data Type Decisions:
--   - transition_id: VARCHAR(50) NOT CITEXT - references fatsmurf.uid (FK relationship)
--   - material_id: VARCHAR(50) NOT CITEXT - references goo.uid (FK relationship)
--   - Note: No timestamp column in original SQL Server table
-- ============================================================================
-- Lineage Model:
--   This table represents TRANSITION → PRODUCT edges in the material lineage graph:
--
--   parent (goo.uid) ──[material_transition]──> transition (fatsmurf.uid)
--                                                        |
--                                                        └──[transition_material]──> product (goo.uid)
--
--   Example: Experiment E1 uses Material M1 as input and produces Material M2 as output:
--     - material_transition: (material_id: M1, transition_id: E1) - INPUT edge
--     - transition_material: (transition_id: E1, material_id: M2) - OUTPUT edge
--
--   Together, these tables form the complete lineage graph for material tracking.
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed transition_id/material_id from CITEXT to VARCHAR(50)
--   2026-01-26 Claude - Added composite PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
--   2026-01-26 Claude - Documented FK relationships (FKs added in T120-T125)
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.transition_material CASCADE;

-- Create transition_material table
CREATE TABLE perseus.transition_material (
    -- Transition/experiment identifier (references fatsmurf.uid)
    transition_id VARCHAR(50) NOT NULL,

    -- Product material identifier (references goo.uid)
    material_id VARCHAR(50) NOT NULL,

    -- Composite primary key (both columns form unique edge)
    CONSTRAINT pk_transition_material PRIMARY KEY (transition_id, material_id)
);

-- ============================================================================
-- Foreign Key Constraints (Added in Phase T120-T125)
-- ============================================================================

-- NOTE: Foreign key constraints will be added in a separate migration phase (T120-T125)
-- after all tables are created to avoid dependency ordering issues.
--
-- Future FK constraints:
--   CONSTRAINT fk_transition_material_fatsmurf
--     FOREIGN KEY (transition_id) REFERENCES perseus.fatsmurf(uid)
--     ON DELETE CASCADE ON UPDATE CASCADE;
--
--   CONSTRAINT fk_transition_material_goo
--     FOREIGN KEY (material_id) REFERENCES perseus.goo(uid)
--     ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.transition_material IS
'Material lineage graph - transition to product material edges.
Represents the relationship: Experiment/Transition → Product Material.
This table stores the OUTGOING edges (materials produced as outputs from transitions).
Paired with material_transition table which stores INCOMING edges (input materials).
Critical for: translated view, mcgetupstream, mcgetdownstream functions.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.transition_material.transition_id IS
'Transition/experiment identifier (references fatsmurf.uid).
Experiment that produces the material as output.';

COMMENT ON COLUMN perseus.transition_material.material_id IS
'Product material identifier (references goo.uid).
Material produced as output from the transition/experiment.';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'transition_material'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'transition_material';

-- Test lineage query pattern (after data loaded)
-- SELECT tm.transition_id, tm.material_id, f.name AS transition_name, g.name AS product_name
-- FROM perseus.transition_material tm
-- INNER JOIN perseus.fatsmurf f ON tm.transition_id = f.uid
-- INNER JOIN perseus.goo g ON tm.material_id = g.uid
-- LIMIT 10;

-- Test complete lineage chain (after data loaded)
-- SELECT
--     g1.name AS parent_material,
--     f.name AS transition,
--     g2.name AS product_material
-- FROM perseus.material_transition mt
-- INNER JOIN perseus.transition_material tm ON mt.transition_id = tm.transition_id
-- INNER JOIN perseus.goo g1 ON mt.material_id = g1.uid
-- INNER JOIN perseus.fatsmurf f ON mt.transition_id = f.uid
-- INNER JOIN perseus.goo g2 ON tm.material_id = g2.uid
-- LIMIT 10;

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.transition_material CASCADE;

-- ============================================================================
-- END OF transition_material TABLE DDL
-- ============================================================================
