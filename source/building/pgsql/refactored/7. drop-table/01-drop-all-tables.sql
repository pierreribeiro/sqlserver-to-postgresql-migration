-- =============================================================================
-- Table Drop - Perseus Database Migration (Reverse Dependency Order)
-- =============================================================================
-- Drops ALL tables in reverse FK dependency order (most dependent first).
-- Idempotent: uses IF EXISTS on every statement.
-- Safe: uses CASCADE to handle any remaining FK references.
--
-- WARNING: This is a DESTRUCTIVE operation. All data will be lost.
-- Ensure backups exist before running in STAGING/PROD environments.
--
-- Total Objects: 101 (91 tables + 8 foreign tables + 1 public table + 1 FDW setup)
-- FK Constraints: 124 (analyzed from 17. create-constraint/02-foreign-key-constraints.sql)
--
-- Counterpart: 14. create-table/*.sql
-- =============================================================================

-- =============================================================================
-- TIER 4: Deepest Dependencies (DROP FIRST)
-- These tables only reference other tables; no table references them.
-- =============================================================================

-- Material Lineage Graph (P0 Critical)
DROP TABLE IF EXISTS perseus.transition_material CASCADE;
DROP TABLE IF EXISTS perseus.material_transition CASCADE;

-- Material Inventory & QC
DROP TABLE IF EXISTS perseus.material_inventory_threshold_notify_user CASCADE;
DROP TABLE IF EXISTS perseus.material_inventory CASCADE;
DROP TABLE IF EXISTS perseus.material_inventory_threshold CASCADE;
DROP TABLE IF EXISTS perseus.material_qc CASCADE;

-- Robot Log Details
DROP TABLE IF EXISTS perseus.robot_log_transfer CASCADE;
DROP TABLE IF EXISTS perseus.robot_log_read CASCADE;
DROP TABLE IF EXISTS perseus.robot_log_error CASCADE;
DROP TABLE IF EXISTS perseus.robot_log_container_sequence CASCADE;

-- Submission
DROP TABLE IF EXISTS perseus.submission_entry CASCADE;

-- Poll
DROP TABLE IF EXISTS perseus.poll_history CASCADE;

-- Fatsmurf Children
DROP TABLE IF EXISTS perseus.fatsmurf_attachment CASCADE;
DROP TABLE IF EXISTS perseus.fatsmurf_comment CASCADE;
DROP TABLE IF EXISTS perseus.fatsmurf_history CASCADE;

-- Goo Children
DROP TABLE IF EXISTS perseus.goo_attachment CASCADE;
DROP TABLE IF EXISTS perseus.goo_comment CASCADE;
DROP TABLE IF EXISTS perseus.goo_history CASCADE;

-- Field Map Display
DROP TABLE IF EXISTS perseus.field_map_display_type_user CASCADE;
DROP TABLE IF EXISTS perseus.field_map_display_type CASCADE;

-- Workflow Children
DROP TABLE IF EXISTS perseus.workflow_attachment CASCADE;
DROP TABLE IF EXISTS perseus.workflow_section CASCADE;

-- Recipe Assignment
DROP TABLE IF EXISTS perseus.recipe_project_assignment CASCADE;

-- Smurf Children
DROP TABLE IF EXISTS perseus.smurf_group_member CASCADE;

-- =============================================================================
-- TIER 3: Third Level Dependencies
-- =============================================================================

-- Core Material Entities (P0 Critical)
DROP TABLE IF EXISTS perseus.goo CASCADE;
DROP TABLE IF EXISTS perseus.fatsmurf CASCADE;
DROP TABLE IF EXISTS perseus.fatsmurf_reading CASCADE;

-- Recipe
DROP TABLE IF EXISTS perseus.recipe_part CASCADE;
DROP TABLE IF EXISTS perseus.recipe CASCADE;

-- Robot
DROP TABLE IF EXISTS perseus.robot_log CASCADE;
DROP TABLE IF EXISTS perseus.robot_run CASCADE;

-- Poll (depends on fatsmurf_reading, smurf_property)
DROP TABLE IF EXISTS perseus.poll CASCADE;

-- Submission
DROP TABLE IF EXISTS perseus.submission CASCADE;

-- =============================================================================
-- TIER 2: Second Level Dependencies
-- =============================================================================

-- COA
DROP TABLE IF EXISTS perseus.coa_spec CASCADE;

-- Container
DROP TABLE IF EXISTS perseus.container_history CASCADE;

-- Field Map
DROP TABLE IF EXISTS perseus.field_map CASCADE;

-- Goo Type Combine
DROP TABLE IF EXISTS perseus.goo_type_combine_component CASCADE;

-- History
DROP TABLE IF EXISTS perseus.history_value CASCADE;

-- Property
DROP TABLE IF EXISTS perseus.property_option CASCADE;

-- Smurf
DROP TABLE IF EXISTS perseus.smurf_property CASCADE;
DROP TABLE IF EXISTS perseus.smurf_goo_type CASCADE;
DROP TABLE IF EXISTS perseus.smurf_group CASCADE;

-- Workflow Step
DROP TABLE IF EXISTS perseus.workflow_step CASCADE;

-- Feed Type
DROP TABLE IF EXISTS perseus.feed_type CASCADE;

-- Saved Search
DROP TABLE IF EXISTS perseus.saved_search CASCADE;

-- =============================================================================
-- TIER 1: First Level Dependencies (reference only Tier 0 tables)
-- =============================================================================

DROP TABLE IF EXISTS perseus.coa CASCADE;
DROP TABLE IF EXISTS perseus.container CASCADE;
DROP TABLE IF EXISTS perseus.container_type_position CASCADE;
DROP TABLE IF EXISTS perseus.external_goo_type CASCADE;
DROP TABLE IF EXISTS perseus.goo_type_combine_target CASCADE;
DROP TABLE IF EXISTS perseus.history CASCADE;
DROP TABLE IF EXISTS perseus.perseus_user CASCADE;
DROP TABLE IF EXISTS perseus.property CASCADE;
DROP TABLE IF EXISTS perseus.robot_log_type CASCADE;
DROP TABLE IF EXISTS perseus.workflow CASCADE;

-- =============================================================================
-- TIER 0: Independent Tables (no FK dependencies)
-- =============================================================================

DROP TABLE IF EXISTS perseus.container_type CASCADE;
DROP TABLE IF EXISTS perseus.goo_type CASCADE;
DROP TABLE IF EXISTS perseus.goo_attachment_type CASCADE;
DROP TABLE IF EXISTS perseus.goo_process_queue_type CASCADE;
DROP TABLE IF EXISTS perseus.manufacturer CASCADE;
DROP TABLE IF EXISTS perseus.unit CASCADE;
DROP TABLE IF EXISTS perseus.display_layout CASCADE;
DROP TABLE IF EXISTS perseus.display_type CASCADE;
DROP TABLE IF EXISTS perseus.workflow_step_type CASCADE;
DROP TABLE IF EXISTS perseus.sequence_type CASCADE;
DROP TABLE IF EXISTS perseus.color CASCADE;
DROP TABLE IF EXISTS perseus.history_type CASCADE;
DROP TABLE IF EXISTS perseus.smurf CASCADE;
DROP TABLE IF EXISTS perseus.person CASCADE;

-- Field Map Support Tables (no incoming FKs)
DROP TABLE IF EXISTS perseus.field_map_block CASCADE;
DROP TABLE IF EXISTS perseus.field_map_set CASCADE;
DROP TABLE IF EXISTS perseus.field_map_type CASCADE;

-- Standalone Tables (no FK relationships)
DROP TABLE IF EXISTS perseus.m_upstream CASCADE;
DROP TABLE IF EXISTS perseus.m_downstream CASCADE;
DROP TABLE IF EXISTS perseus.m_upstream_dirty_leaves CASCADE;
DROP TABLE IF EXISTS perseus.m_number CASCADE;
DROP TABLE IF EXISTS perseus.s_number CASCADE;
DROP TABLE IF EXISTS perseus.prefix_incrementor CASCADE;
DROP TABLE IF EXISTS perseus.migration CASCADE;
DROP TABLE IF EXISTS perseus.scraper CASCADE;
DROP TABLE IF EXISTS perseus.tmp_messy_links CASCADE;
DROP TABLE IF EXISTS perseus.permissions CASCADE;
DROP TABLE IF EXISTS perseus.perseus_table_and_row_counts CASCADE;

-- CM Tables (no FK relationships in migration scope)
DROP TABLE IF EXISTS perseus.cm_application CASCADE;
DROP TABLE IF EXISTS perseus.cm_application_group CASCADE;
DROP TABLE IF EXISTS perseus.cm_group CASCADE;
DROP TABLE IF EXISTS perseus.cm_project CASCADE;
DROP TABLE IF EXISTS perseus.cm_unit CASCADE;
DROP TABLE IF EXISTS perseus.cm_unit_compare CASCADE;
DROP TABLE IF EXISTS perseus.cm_unit_dimensions CASCADE;
DROP TABLE IF EXISTS perseus.cm_user CASCADE;
DROP TABLE IF EXISTS perseus.cm_user_group CASCADE;

-- =============================================================================
-- HERMES SCHEMA - Foreign Tables (FDW)
-- =============================================================================

DROP FOREIGN TABLE IF EXISTS hermes.run_condition_value CASCADE;
DROP FOREIGN TABLE IF EXISTS hermes.run_condition_option CASCADE;
DROP FOREIGN TABLE IF EXISTS hermes.run_condition CASCADE;
DROP FOREIGN TABLE IF EXISTS hermes.run_master_condition CASCADE;
DROP FOREIGN TABLE IF EXISTS hermes.run_master_condition_type CASCADE;
DROP FOREIGN TABLE IF EXISTS hermes.run CASCADE;

-- =============================================================================
-- DEMETER SCHEMA - Foreign Tables (FDW)
-- =============================================================================

DROP FOREIGN TABLE IF EXISTS demeter.barcodes CASCADE;
DROP FOREIGN TABLE IF EXISTS demeter.seed_vials CASCADE;

-- =============================================================================
-- PUBLIC SCHEMA
-- =============================================================================

DROP TABLE IF EXISTS public.alembic_version CASCADE;

-- =============================================================================
-- END OF DROP TABLE SCRIPT
-- =============================================================================
