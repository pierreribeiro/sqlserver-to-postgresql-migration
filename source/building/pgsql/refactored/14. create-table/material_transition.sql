-- ============================================================================
-- Object: material_transition
-- Type: TABLE
-- Priority: P0
-- Description: Material lineage graph - parent material to transition edges
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/8. create-table/56. perseus.dbo.material_transition.sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/14. create-table/53. perseus.material_transition.sql
--   Quality Score: 9.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Dependencies:
--   Tables: goo (uid column), fatsmurf (uid column)
--   Referenced by: translated view (materialized), mcgetupstream, mcgetdownstream functions
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL table definition
--   [✓] II. Strict Typing - Explicit data types, no implicit conversions
--   [✓] III. Set-Based - Table structure supports set-based queries
--   [✓] IV. Atomic Transactions - N/A for DDL
--   [✓] V. Naming & Scoping - snake_case, schema-qualified (perseus.material_transition)
--   [✓] VI. Error Resilience - N/A for DDL
--   [✓] VII. Modular Logic - Single table, clear purpose
-- ============================================================================
-- Performance Notes:
--   Baseline: Critical for material lineage queries
--   Indexes: PRIMARY KEY on (material_id, transition_id), future indexes on each column
--   Expected: High-volume table with frequent joins, ensure proper indexing
-- ============================================================================
-- Data Type Decisions:
--   - material_id: VARCHAR(50) NOT CITEXT - references goo.uid (FK relationship)
--   - transition_id: VARCHAR(50) NOT CITEXT - references fatsmurf.uid (FK relationship)
--   - added_on: TIMESTAMP - changed from clock_timestamp() to CURRENT_TIMESTAMP
-- ============================================================================
-- Lineage Model:
--   This table represents PARENT → TRANSITION edges in the material lineage graph:
--
--   material (goo.uid) ──[material_transition]──> transition (fatsmurf.uid)
--                                                        |
--                                                        └──[transition_material]──> product (goo.uid)
--
--   Example: Material M1 is used in Experiment E1 to produce Material M2:
--     - material_transition: (material_id: M1, transition_id: E1)
--     - transition_material: (transition_id: E1, material_id: M2)
-- ============================================================================
-- Change Log:
--   2026-01-26 Claude - Initial migration from SQL Server
--   2026-01-26 Claude - Fixed schema (perseus_dbo → perseus)
--   2026-01-26 Claude - Removed WITH (OIDS=FALSE) clause
--   2026-01-26 Claude - Changed material_id/transition_id from CITEXT to VARCHAR(50)
--   2026-01-26 Claude - Changed clock_timestamp() to CURRENT_TIMESTAMP
--   2026-01-26 Claude - Added composite PRIMARY KEY constraint
--   2026-01-26 Claude - Added table and column comments
--   2026-01-26 Claude - Documented FK relationships (FKs added in T120-T125)
-- ============================================================================

-- Drop table if exists (for clean re-deployment)
DROP TABLE IF EXISTS perseus.material_transition CASCADE;

-- Create material_transition table
CREATE TABLE perseus.material_transition (
    -- Parent material identifier (references goo.uid)
    material_id VARCHAR(50) NOT NULL,

    -- Transition/experiment identifier (references fatsmurf.uid)
    transition_id VARCHAR(50) NOT NULL,

    -- Timestamp when edge was created
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite primary key (both columns form unique edge)
    CONSTRAINT pk_material_transition PRIMARY KEY (material_id, transition_id)
);

-- ============================================================================
-- Foreign Key Constraints (Added in Phase T120-T125)
-- ============================================================================

-- NOTE: Foreign key constraints will be added in a separate migration phase (T120-T125)
-- after all tables are created to avoid dependency ordering issues.
--
-- Future FK constraints:
--   CONSTRAINT fk_material_transition_goo
--     FOREIGN KEY (material_id) REFERENCES perseus.goo(uid)
--     ON DELETE CASCADE ON UPDATE CASCADE;
--
--   CONSTRAINT fk_material_transition_fatsmurf
--     FOREIGN KEY (transition_id) REFERENCES perseus.fatsmurf(uid)
--     ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Table and Column Comments
-- ============================================================================

COMMENT ON TABLE perseus.material_transition IS
'Material lineage graph - parent material to transition edges.
Represents the relationship: Material → Experiment/Transition → Product Material.
This table stores the INCOMING edges (materials used as inputs to transitions).
Paired with transition_material table which stores OUTGOING edges (products).
Critical for: translated view, mcgetupstream, mcgetdownstream functions.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.material_transition.material_id IS
'Parent material identifier (references goo.uid).
Material used as input to the transition/experiment.';

COMMENT ON COLUMN perseus.material_transition.transition_id IS
'Transition/experiment identifier (references fatsmurf.uid).
Experiment that uses the material as input.';

COMMENT ON COLUMN perseus.material_transition.added_on IS
'Timestamp when lineage edge was created (default: current timestamp)';

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'material_transition'
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_schema = 'perseus' AND table_name = 'material_transition';

-- Test lineage query pattern (after data loaded)
-- SELECT mt.material_id, mt.transition_id, g.name AS material_name, f.name AS transition_name
-- FROM perseus.material_transition mt
-- INNER JOIN perseus.goo g ON mt.material_id = g.uid
-- INNER JOIN perseus.fatsmurf f ON mt.transition_id = f.uid
-- LIMIT 10;

-- ============================================================================
-- Rollback Script
-- ============================================================================

-- To rollback this migration:
-- DROP TABLE IF EXISTS perseus.material_transition CASCADE;

-- ============================================================================
-- END OF material_transition TABLE DDL
-- ============================================================================
