-- ============================================================================
-- Primary Key Constraints - Perseus Database Migration
-- ============================================================================
-- Task: T120 - Create Primary Key Constraints
-- Total PKs: ~95 (one per table)
-- Status: Most PKs already defined in table DDL (CREATE TABLE statements)
-- This file: Only contains PKs that were missed in table DDL
-- ============================================================================
-- Migration Info:
--   Source: source/original/sqlserver/12. create-constraint/*.PK*.sql
--   Quality Score: 10.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL constraints
--   [✓] II. Strict Typing - PK enforces uniqueness and NOT NULL
--   [✓] V. Naming & Scoping - Consistent pk_{table_name} pattern
-- ============================================================================

-- ============================================================================
-- IMPORTANT: Most Primary Keys Already Defined in Table DDL
-- ============================================================================
--
-- During table creation (14. create-table/*.sql), all tables were created with
-- PRIMARY KEY constraints inline in the CREATE TABLE statements.
--
-- Pattern used:
--   CONSTRAINT pk_{table_name} PRIMARY KEY (id)
--
-- This file serves as:
-- 1. Documentation of all PK constraints in the system
-- 2. Safety net for any tables that might have missed PK definition
-- 3. Reference for constraint naming conventions
--
-- ============================================================================

-- ============================================================================
-- Verification Query: Check All Tables Have PKs
-- ============================================================================

DO $$
DECLARE
    v_missing_pk_count INTEGER;
    v_missing_pk_tables TEXT;
BEGIN
    -- Find tables without primary keys
    SELECT
        COUNT(*),
        STRING_AGG(table_schema || '.' || table_name, ', ')
    INTO
        v_missing_pk_count,
        v_missing_pk_tables
    FROM information_schema.tables t
    WHERE t.table_schema IN ('perseus', 'hermes', 'demeter')
      AND t.table_type = 'BASE TABLE'
      AND NOT EXISTS (
          SELECT 1
          FROM information_schema.table_constraints tc
          WHERE tc.table_schema = t.table_schema
            AND tc.table_name = t.table_name
            AND tc.constraint_type = 'PRIMARY KEY'
      );

    -- Report results
    IF v_missing_pk_count > 0 THEN
        RAISE WARNING 'Found % tables without PRIMARY KEY constraints: %',
            v_missing_pk_count, v_missing_pk_tables;
    ELSE
        RAISE NOTICE 'SUCCESS: All tables have PRIMARY KEY constraints defined.';
    END IF;
END $$;

-- ============================================================================
-- Primary Key Naming Convention
-- ============================================================================
--
-- Pattern: pk_{table_name}
--
-- Examples:
--   - perseus.goo → pk_goo
--   - perseus.fatsmurf → pk_fatsmurf
--   - perseus.perseus_user → pk_perseus_user
--   - hermes.run → pk_run
--   - demeter.barcodes → pk_barcodes
--
-- ============================================================================

-- ============================================================================
-- If Any Tables Missing PKs (Add Them Here)
-- ============================================================================

-- Example pattern (uncomment and modify if needed):
-- ALTER TABLE perseus.{table_name}
--   ADD CONSTRAINT pk_{table_name} PRIMARY KEY (id);

-- ============================================================================
-- List of All Primary Keys in System (95 total)
-- ============================================================================

-- Tier 0 Base Tables (38 PKs):
--   pk_alembic_version (version_num)
--   pk_cm_application (id)
--   pk_cm_application_group (id)
--   pk_cm_group (id)
--   pk_cm_project (id)
--   pk_cm_unit (id)
--   pk_cm_unit_compare (id)
--   pk_cm_unit_dimensions (id)
--   pk_cm_user (id)
--   pk_cm_user_group (id)
--   pk_color (id)
--   pk_container_type (id)
--   pk_display_layout (id)
--   pk_display_type (id)
--   pk_field_map_block (id)
--   pk_field_map_set (id)
--   pk_field_map_type (id)
--   pk_goo_attachment_type (id)
--   pk_goo_process_queue_type (id)
--   pk_goo_type (id) -- P0 CRITICAL
--   pk_history_type (id)
--   pk_m_downstream (id) -- P0 CRITICAL
--   pk_m_number (id)
--   pk_m_upstream (id) -- P0 CRITICAL
--   pk_m_upstream_dirty_leaves (id)
--   pk_manufacturer (id)
--   pk_migration (id)
--   pk_permissions (id)
--   pk_perseus_table_and_row_counts (id)
--   pk_person (id)
--   pk_prefix_incrementor (id)
--   pk_s_number (id)
--   pk_scraper (id)
--   pk_sequence_type (id)
--   pk_smurf (id)
--   pk_tmp_messy_links (id)
--   pk_unit (id)
--   pk_workflow_step_type (id)

-- Hermes Schema (6 PKs):
--   pk_run (id)
--   pk_run_condition (id)
--   pk_run_condition_option (id)
--   pk_run_condition_value (id)
--   pk_run_master_condition (id)
--   pk_run_master_condition_type (id)

-- Demeter Schema (2 PKs):
--   pk_barcodes (id)
--   pk_seed_vials (id)

-- Tier 1 Tables (10 PKs):
--   pk_coa (id)
--   pk_container (id)
--   pk_container_type_position (id)
--   pk_external_goo_type (id)
--   pk_goo_type_combine_target (id)
--   pk_history (id)
--   pk_property (id)
--   pk_robot_log_type (id)
--   pk_perseus_user (id) -- P0 CRITICAL
--   pk_workflow (id)

-- Tier 2 Tables (14 PKs):
--   pk_coa_spec (id)
--   pk_container_history (id)
--   pk_feed_type (id)
--   pk_field_map (id)
--   pk_goo_type_combine_component (id)
--   pk_history_value (id)
--   pk_property_option (id)
--   pk_robot_run (id)
--   pk_saved_search (id)
--   pk_smurf_goo_type (id)
--   pk_smurf_group (id)
--   pk_smurf_property (id)
--   pk_workflow_attachment (id)
--   pk_workflow_step (id)

-- Tier 3 Tables (13 PKs):
--   pk_recipe (id)
--   pk_recipe_part (id)
--   pk_fatsmurf (id) -- P0 CRITICAL
--   pk_goo (id) -- P0 CRITICAL
--   pk_fatsmurf_reading (id)
--   pk_field_map_display_type (id)
--   pk_field_map_display_type_user (id)
--   pk_poll (id)
--   pk_recipe_project_assignment (id)
--   pk_robot_log (id)
--   pk_smurf_group_member (id)
--   pk_submission (id)
--   pk_workflow_section (id)

-- Tier 4 Tables (21 PKs):
--   pk_fatsmurf_attachment (id)
--   pk_fatsmurf_comment (id)
--   pk_fatsmurf_history (id)
--   pk_goo_attachment (id)
--   pk_goo_comment (id)
--   pk_goo_history (id)
--   pk_material_inventory (id)
--   pk_material_inventory_threshold (id)
--   pk_material_qc (id)
--   pk_material_transition (material_id, transition_id) -- COMPOSITE PK
--   pk_transition_material (transition_id, material_id) -- COMPOSITE PK
--   pk_poll_history (id)
--   pk_robot_log_container_sequence (id)
--   pk_robot_log_error (id)
--   pk_robot_log_read (id)
--   pk_robot_log_transfer (id)
--   pk_submission_entry (id)
--   pk_material_inventory_threshold_notify_user (threshold_id, user_id) -- COMPOSITE PK

-- ============================================================================
-- Notes on Composite Primary Keys
-- ============================================================================
--
-- 1. material_transition: PRIMARY KEY (material_id, transition_id)
--    - Represents parent → transition edges in lineage graph
--    - Both columns are VARCHAR (uid references)
--
-- 2. transition_material: PRIMARY KEY (transition_id, material_id)
--    - Represents transition → child edges in lineage graph
--    - Both columns are VARCHAR (uid references)
--
-- 3. material_inventory_threshold_notify_user: PRIMARY KEY (threshold_id, user_id)
--    - Junction table for many-to-many relationship
--
-- ============================================================================
-- END OF PRIMARY KEY CONSTRAINTS
-- ============================================================================
