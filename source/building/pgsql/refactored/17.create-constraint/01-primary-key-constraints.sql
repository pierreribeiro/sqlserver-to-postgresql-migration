-- =============================================================================
-- File: 01-primary-key-constraints.sql
-- Purpose: Add primary key constraints to all Perseus schema tables
--
-- Migration: SQL Server → PostgreSQL 17+
-- Schema: perseus
--
-- Notes:
--   - All tables use ALTER TABLE ADD CONSTRAINT (not inline in CREATE TABLE)
--   - FDW tables (hermes.*, demeter.*) are excluded - no PKs on foreign tables
--   - Most tables use single-column PK on (id) with naming convention pk_{table_name}
--   - Special cases:
--       * alembic_version: PK on (version_num) - constraint name: alembic_version_pkc
--       * material_transition: Composite PK on (material_id, transition_id)
--       * transition_material: Composite PK on (transition_id, material_id)
--       * material_inventory_threshold_notify_user: Composite PK on (threshold_id, user_id)
--
-- Execution Order: Run after all CREATE TABLE statements (14. create-table/)
-- Dependencies: All perseus schema tables must exist
-- Idempotent: No - will fail if constraints already exist. Drop constraints first if re-running.
-- =============================================================================

SET search_path TO perseus, public;

-- =============================================================================
-- SPECIAL CASE: alembic_version
-- =============================================================================
-- Alembic migration tracking table uses version_num as PK (not id)
ALTER TABLE perseus.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);

-- =============================================================================
-- TIER 0: Base Tables (38 tables)
-- =============================================================================

ALTER TABLE perseus.cm_application
    ADD CONSTRAINT pk_cm_application PRIMARY KEY (id);

ALTER TABLE perseus.cm_application_group
    ADD CONSTRAINT pk_cm_application_group PRIMARY KEY (id);

ALTER TABLE perseus.cm_group
    ADD CONSTRAINT pk_cm_group PRIMARY KEY (id);

ALTER TABLE perseus.cm_project
    ADD CONSTRAINT pk_cm_project PRIMARY KEY (id);

ALTER TABLE perseus.cm_unit
    ADD CONSTRAINT pk_cm_unit PRIMARY KEY (id);

ALTER TABLE perseus.cm_unit_compare
    ADD CONSTRAINT pk_cm_unit_compare PRIMARY KEY (id);

ALTER TABLE perseus.cm_unit_dimensions
    ADD CONSTRAINT pk_cm_unit_dimensions PRIMARY KEY (id);

ALTER TABLE perseus.cm_user
    ADD CONSTRAINT pk_cm_user PRIMARY KEY (id);

ALTER TABLE perseus.cm_user_group
    ADD CONSTRAINT pk_cm_user_group PRIMARY KEY (id);

ALTER TABLE perseus.color
    ADD CONSTRAINT pk_color PRIMARY KEY (id);

ALTER TABLE perseus.container_type
    ADD CONSTRAINT pk_container_type PRIMARY KEY (id);

ALTER TABLE perseus.display_layout
    ADD CONSTRAINT pk_display_layout PRIMARY KEY (id);

ALTER TABLE perseus.display_type
    ADD CONSTRAINT pk_display_type PRIMARY KEY (id);

ALTER TABLE perseus.field_map_block
    ADD CONSTRAINT pk_field_map_block PRIMARY KEY (id);

ALTER TABLE perseus.field_map_set
    ADD CONSTRAINT pk_field_map_set PRIMARY KEY (id);

ALTER TABLE perseus.field_map_type
    ADD CONSTRAINT pk_field_map_type PRIMARY KEY (id);

ALTER TABLE perseus.goo_attachment_type
    ADD CONSTRAINT pk_goo_attachment_type PRIMARY KEY (id);

ALTER TABLE perseus.goo_process_queue_type
    ADD CONSTRAINT pk_goo_process_queue_type PRIMARY KEY (id);

ALTER TABLE perseus.goo_type
    ADD CONSTRAINT pk_goo_type PRIMARY KEY (id);

ALTER TABLE perseus.history_type
    ADD CONSTRAINT pk_history_type PRIMARY KEY (id);

ALTER TABLE perseus.m_downstream
    ADD CONSTRAINT pk_m_downstream PRIMARY KEY (id);

ALTER TABLE perseus.m_number
    ADD CONSTRAINT pk_m_number PRIMARY KEY (id);

ALTER TABLE perseus.m_upstream
    ADD CONSTRAINT pk_m_upstream PRIMARY KEY (id);

ALTER TABLE perseus.m_upstream_dirty_leaves
    ADD CONSTRAINT pk_m_upstream_dirty_leaves PRIMARY KEY (id);

ALTER TABLE perseus.manufacturer
    ADD CONSTRAINT pk_manufacturer PRIMARY KEY (id);

ALTER TABLE perseus.migration
    ADD CONSTRAINT pk_migration PRIMARY KEY (id);

ALTER TABLE perseus.permissions
    ADD CONSTRAINT pk_permissions PRIMARY KEY (id);

ALTER TABLE perseus.perseus_table_and_row_counts
    ADD CONSTRAINT pk_perseus_table_and_row_counts PRIMARY KEY (id);

ALTER TABLE perseus.person
    ADD CONSTRAINT pk_person PRIMARY KEY (id);

ALTER TABLE perseus.prefix_incrementor
    ADD CONSTRAINT pk_prefix_incrementor PRIMARY KEY (id);

ALTER TABLE perseus.s_number
    ADD CONSTRAINT pk_s_number PRIMARY KEY (id);

ALTER TABLE perseus.scraper
    ADD CONSTRAINT pk_scraper PRIMARY KEY (id);

ALTER TABLE perseus.sequence_type
    ADD CONSTRAINT pk_sequence_type PRIMARY KEY (id);

ALTER TABLE perseus.smurf
    ADD CONSTRAINT pk_smurf PRIMARY KEY (id);

ALTER TABLE perseus.tmp_messy_links
    ADD CONSTRAINT pk_tmp_messy_links PRIMARY KEY (id);

ALTER TABLE perseus.unit
    ADD CONSTRAINT pk_unit PRIMARY KEY (id);

ALTER TABLE perseus.workflow_step_type
    ADD CONSTRAINT pk_workflow_step_type PRIMARY KEY (id);

-- =============================================================================
-- TIER 1: First-Level Dependencies (10 tables)
-- =============================================================================

ALTER TABLE perseus.coa
    ADD CONSTRAINT pk_coa PRIMARY KEY (id);

ALTER TABLE perseus.container
    ADD CONSTRAINT pk_container PRIMARY KEY (id);

ALTER TABLE perseus.container_type_position
    ADD CONSTRAINT pk_container_type_position PRIMARY KEY (id);

ALTER TABLE perseus.external_goo_type
    ADD CONSTRAINT pk_external_goo_type PRIMARY KEY (id);

ALTER TABLE perseus.goo_type_combine_target
    ADD CONSTRAINT pk_goo_type_combine_target PRIMARY KEY (id);

ALTER TABLE perseus.history
    ADD CONSTRAINT pk_history PRIMARY KEY (id);

ALTER TABLE perseus.property
    ADD CONSTRAINT pk_property PRIMARY KEY (id);

ALTER TABLE perseus.robot_log_type
    ADD CONSTRAINT pk_robot_log_type PRIMARY KEY (id);

ALTER TABLE perseus.perseus_user
    ADD CONSTRAINT pk_perseus_user PRIMARY KEY (id);

ALTER TABLE perseus.workflow
    ADD CONSTRAINT pk_workflow PRIMARY KEY (id);

-- =============================================================================
-- TIER 2: Second-Level Dependencies (14 tables)
-- =============================================================================

ALTER TABLE perseus.coa_spec
    ADD CONSTRAINT pk_coa_spec PRIMARY KEY (id);

ALTER TABLE perseus.container_history
    ADD CONSTRAINT pk_container_history PRIMARY KEY (id);

ALTER TABLE perseus.feed_type
    ADD CONSTRAINT pk_feed_type PRIMARY KEY (id);

ALTER TABLE perseus.field_map
    ADD CONSTRAINT pk_field_map PRIMARY KEY (id);

ALTER TABLE perseus.goo_type_combine_component
    ADD CONSTRAINT pk_goo_type_combine_component PRIMARY KEY (id);

ALTER TABLE perseus.history_value
    ADD CONSTRAINT pk_history_value PRIMARY KEY (id);

ALTER TABLE perseus.property_option
    ADD CONSTRAINT pk_property_option PRIMARY KEY (id);

ALTER TABLE perseus.robot_run
    ADD CONSTRAINT pk_robot_run PRIMARY KEY (id);

ALTER TABLE perseus.saved_search
    ADD CONSTRAINT pk_saved_search PRIMARY KEY (id);

ALTER TABLE perseus.smurf_goo_type
    ADD CONSTRAINT pk_smurf_goo_type PRIMARY KEY (id);

ALTER TABLE perseus.smurf_group
    ADD CONSTRAINT pk_smurf_group PRIMARY KEY (id);

ALTER TABLE perseus.smurf_property
    ADD CONSTRAINT pk_smurf_property PRIMARY KEY (id);

ALTER TABLE perseus.workflow_attachment
    ADD CONSTRAINT pk_workflow_attachment PRIMARY KEY (id);

ALTER TABLE perseus.workflow_step
    ADD CONSTRAINT pk_workflow_step PRIMARY KEY (id);

-- =============================================================================
-- TIER 3: Third-Level Dependencies (13 tables)
-- =============================================================================

ALTER TABLE perseus.recipe
    ADD CONSTRAINT pk_recipe PRIMARY KEY (id);

ALTER TABLE perseus.recipe_part
    ADD CONSTRAINT pk_recipe_part PRIMARY KEY (id);

ALTER TABLE perseus.fatsmurf
    ADD CONSTRAINT pk_fatsmurf PRIMARY KEY (id);

ALTER TABLE perseus.goo
    ADD CONSTRAINT pk_goo PRIMARY KEY (id);

ALTER TABLE perseus.fatsmurf_reading
    ADD CONSTRAINT pk_fatsmurf_reading PRIMARY KEY (id);

ALTER TABLE perseus.field_map_display_type
    ADD CONSTRAINT pk_field_map_display_type PRIMARY KEY (id);

ALTER TABLE perseus.field_map_display_type_user
    ADD CONSTRAINT pk_field_map_display_type_user PRIMARY KEY (id);

ALTER TABLE perseus.poll
    ADD CONSTRAINT pk_poll PRIMARY KEY (id);

ALTER TABLE perseus.recipe_project_assignment
    ADD CONSTRAINT pk_recipe_project_assignment PRIMARY KEY (id);

ALTER TABLE perseus.robot_log
    ADD CONSTRAINT pk_robot_log PRIMARY KEY (id);

ALTER TABLE perseus.smurf_group_member
    ADD CONSTRAINT pk_smurf_group_member PRIMARY KEY (id);

ALTER TABLE perseus.submission
    ADD CONSTRAINT pk_submission PRIMARY KEY (id);

ALTER TABLE perseus.workflow_section
    ADD CONSTRAINT pk_workflow_section PRIMARY KEY (id);

-- =============================================================================
-- TIER 4: Fourth-Level Dependencies (15 tables)
-- =============================================================================

ALTER TABLE perseus.fatsmurf_attachment
    ADD CONSTRAINT pk_fatsmurf_attachment PRIMARY KEY (id);

ALTER TABLE perseus.fatsmurf_comment
    ADD CONSTRAINT pk_fatsmurf_comment PRIMARY KEY (id);

ALTER TABLE perseus.fatsmurf_history
    ADD CONSTRAINT pk_fatsmurf_history PRIMARY KEY (id);

ALTER TABLE perseus.goo_attachment
    ADD CONSTRAINT pk_goo_attachment PRIMARY KEY (id);

ALTER TABLE perseus.goo_comment
    ADD CONSTRAINT pk_goo_comment PRIMARY KEY (id);

ALTER TABLE perseus.goo_history
    ADD CONSTRAINT pk_goo_history PRIMARY KEY (id);

ALTER TABLE perseus.material_inventory
    ADD CONSTRAINT pk_material_inventory PRIMARY KEY (id);

ALTER TABLE perseus.material_inventory_threshold
    ADD CONSTRAINT pk_material_inventory_threshold PRIMARY KEY (id);

ALTER TABLE perseus.material_qc
    ADD CONSTRAINT pk_material_qc PRIMARY KEY (id);

ALTER TABLE perseus.poll_history
    ADD CONSTRAINT pk_poll_history PRIMARY KEY (id);

ALTER TABLE perseus.robot_log_container_sequence
    ADD CONSTRAINT pk_robot_log_container_sequence PRIMARY KEY (id);

ALTER TABLE perseus.robot_log_error
    ADD CONSTRAINT pk_robot_log_error PRIMARY KEY (id);

ALTER TABLE perseus.robot_log_read
    ADD CONSTRAINT pk_robot_log_read PRIMARY KEY (id);

ALTER TABLE perseus.robot_log_transfer
    ADD CONSTRAINT pk_robot_log_transfer PRIMARY KEY (id);

ALTER TABLE perseus.submission_entry
    ADD CONSTRAINT pk_submission_entry PRIMARY KEY (id);

-- =============================================================================
-- COMPOSITE PRIMARY KEYS (3 tables)
-- =============================================================================

-- Material ↔ Transition edges (parent → transition in lineage graph)
ALTER TABLE perseus.material_transition
    ADD CONSTRAINT pk_material_transition PRIMARY KEY (material_id, transition_id);

-- Transition ↔ Material edges (transition → child in lineage graph)
ALTER TABLE perseus.transition_material
    ADD CONSTRAINT pk_transition_material PRIMARY KEY (transition_id, material_id);

-- Threshold ↔ User notification junction table
ALTER TABLE perseus.material_inventory_threshold_notify_user
    ADD CONSTRAINT pk_material_inventory_threshold_notify_user PRIMARY KEY (threshold_id, user_id);

-- =============================================================================
-- VERIFICATION
-- =============================================================================

DO $$
DECLARE
    v_missing_pks INTEGER;
    v_table_name TEXT;
BEGIN
    SELECT COUNT(*) INTO v_missing_pks
    FROM information_schema.tables t
    WHERE t.table_schema = 'perseus'
      AND t.table_type = 'BASE TABLE'
      AND NOT EXISTS (
          SELECT 1
          FROM information_schema.table_constraints tc
          WHERE tc.table_schema = t.table_schema
            AND tc.table_name = t.table_name
            AND tc.constraint_type = 'PRIMARY KEY'
      );

    IF v_missing_pks > 0 THEN
        RAISE NOTICE 'WARNING: % perseus tables are missing primary keys:', v_missing_pks;
        FOR v_table_name IN
            SELECT t.table_name
            FROM information_schema.tables t
            WHERE t.table_schema = 'perseus'
              AND t.table_type = 'BASE TABLE'
              AND NOT EXISTS (
                  SELECT 1
                  FROM information_schema.table_constraints tc
                  WHERE tc.table_schema = t.table_schema
                    AND tc.table_name = t.table_name
                    AND tc.constraint_type = 'PRIMARY KEY'
              )
            ORDER BY t.table_name
        LOOP
            RAISE NOTICE '  - perseus.%', v_table_name;
        END LOOP;
    ELSE
        RAISE NOTICE 'SUCCESS: All % perseus tables have primary key constraints',
            (SELECT COUNT(*) FROM information_schema.tables
             WHERE table_schema = 'perseus' AND table_type = 'BASE TABLE');
    END IF;
END $$;

-- =============================================================================
-- SUMMARY
-- =============================================================================
-- Total: 94 primary key constraints
--   - Single-column PKs on (id): 90
--   - Composite PKs: 3 (material_transition, transition_material,
--                        material_inventory_threshold_notify_user)
--   - Special: 1 (alembic_version on version_num)
--
-- Excluded: 8 FDW foreign tables (hermes.*, demeter.*)
-- =============================================================================
