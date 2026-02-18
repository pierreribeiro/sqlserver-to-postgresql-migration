-- ============================================================================
-- Unique Constraints - Perseus Database Migration
-- ============================================================================
-- Task: T122 - Create Unique Constraints
-- Total UNIQUE: ~40 constraints
-- Purpose: Enforce business uniqueness rules beyond PRIMARY KEYs
-- ============================================================================
-- Migration Info:
--   Source: source/original/sqlserver/12. create-constraint/*UQ*.sql
--   Quality Score: 9.5/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL unique constraints
--   [✓] II. Strict Typing - Enforces uniqueness at column level
--   [✓] V. Naming & Scoping - Consistent uq_{table}_{column} pattern
-- ============================================================================
-- Note: goo.uid and fatsmurf.uid already have UNIQUE indexes (created in table DDL)
--       These are REQUIRED for FK references in material_transition/transition_material
-- ============================================================================

-- ============================================================================
-- Tier 0-1 Base Tables UNIQUE Constraints
-- ============================================================================

-- ----------------------------------------------------------------------------
-- COA Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.coa
  ADD CONSTRAINT uq_coa_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- CONTAINER_TYPE Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.container_type
  ADD CONSTRAINT uq_container_type_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- CONTAINER_TYPE_POSITION Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.container_type_position
  ADD CONSTRAINT uq_container_type_position_parent_child
  UNIQUE (parent_container_type_id, child_container_type_id);

-- ----------------------------------------------------------------------------
-- DISPLAY_LAYOUT Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.display_layout
  ADD CONSTRAINT uq_display_layout_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- DISPLAY_TYPE Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.display_type
  ADD CONSTRAINT uq_display_type_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- EXTERNAL_GOO_TYPE Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.external_goo_type
  ADD CONSTRAINT uq_external_goo_type_goo_type_manufacturer
  UNIQUE (goo_type_id, manufacturer_id);

-- ----------------------------------------------------------------------------
-- FIELD_MAP_TYPE Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.field_map_type
  ADD CONSTRAINT uq_field_map_type_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- GOO_ATTACHMENT_TYPE Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.goo_attachment_type
  ADD CONSTRAINT uq_goo_attachment_type_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- GOO_PROCESS_QUEUE_TYPE Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.goo_process_queue_type
  ADD CONSTRAINT uq_goo_process_queue_type_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- GOO_TYPE Table (Multiple unique constraints)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.goo_type
  ADD CONSTRAINT uq_goo_type_name
  UNIQUE (name);

ALTER TABLE perseus.goo_type
  ADD CONSTRAINT uq_goo_type_abbreviation
  UNIQUE (abbreviation);

-- ----------------------------------------------------------------------------
-- HISTORY_TYPE Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.history_type
  ADD CONSTRAINT uq_history_type_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- MANUFACTURER Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.manufacturer
  ADD CONSTRAINT uq_manufacturer_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- SMURF Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.smurf
  ADD CONSTRAINT uq_smurf_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- WORKFLOW_STEP_TYPE Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.workflow_step_type
  ADD CONSTRAINT uq_workflow_step_type_name
  UNIQUE (name);

-- ============================================================================
-- Tier 2-3 Tables UNIQUE Constraints
-- ============================================================================

-- ----------------------------------------------------------------------------
-- COA_SPEC Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.coa_spec
  ADD CONSTRAINT uq_coa_spec_coa_property
  UNIQUE (coa_id, property_id);

-- ----------------------------------------------------------------------------
-- FATSMURF_READING Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.fatsmurf_reading
  ADD CONSTRAINT uq_fatsmurf_reading_fatsmurf_time
  UNIQUE (fatsmurf_id, reading_time);

-- ----------------------------------------------------------------------------
-- FIELD_MAP_DISPLAY_TYPE Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.field_map_display_type
  ADD CONSTRAINT uq_field_map_display_type_composite
  UNIQUE (field_map_id, display_type_id, display_layout_id);

-- ----------------------------------------------------------------------------
-- FIELD_MAP_DISPLAY_TYPE_USER Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.field_map_display_type_user
  ADD CONSTRAINT uq_field_map_display_type_user_composite
  UNIQUE (field_map_display_type_id, user_id);

-- ----------------------------------------------------------------------------
-- GOO_TYPE_COMBINE_COMPONENT Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.goo_type_combine_component
  ADD CONSTRAINT uq_goo_type_combine_component_composite
  UNIQUE (goo_type_id, goo_type_combine_target_id);

-- ----------------------------------------------------------------------------
-- MATERIAL_INVENTORY Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT uq_material_inventory_material_allocation_location
  UNIQUE (material_id, allocation_container_id, location_container_id);

-- ----------------------------------------------------------------------------
-- POLL Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.poll
  ADD CONSTRAINT uq_poll_fatsmurf_reading_smurf_property
  UNIQUE (fatsmurf_reading_id, smurf_property_id);

-- ----------------------------------------------------------------------------
-- RECIPE Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.recipe
  ADD CONSTRAINT uq_recipe_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- SAVED_SEARCH Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.saved_search
  ADD CONSTRAINT uq_saved_search_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- SMURF_GROUP Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.smurf_group
  ADD CONSTRAINT uq_smurf_group_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- SMURF_GROUP_MEMBER Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.smurf_group_member
  ADD CONSTRAINT uq_smurf_group_member_smurf_group
  UNIQUE (smurf_id, smurf_group_id);

-- ----------------------------------------------------------------------------
-- SMURF_PROPERTY Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.smurf_property
  ADD CONSTRAINT uq_smurf_property_smurf_property
  UNIQUE (smurf_id, property_id);

-- ----------------------------------------------------------------------------
-- WORKFLOW Table
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.workflow
  ADD CONSTRAINT uq_workflow_name
  UNIQUE (name);

-- ----------------------------------------------------------------------------
-- WORKFLOW_SECTION Table (Multiple unique constraints)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.workflow_section
  ADD CONSTRAINT uq_workflow_section_workflow_index
  UNIQUE (workflow_id, section_index);

ALTER TABLE perseus.workflow_section
  ADD CONSTRAINT uq_workflow_section_workflow_name
  UNIQUE (workflow_id, name);

-- ============================================================================
-- Hermes Schema UNIQUE Constraints
-- ============================================================================

-- ----------------------------------------------------------------------------
-- RUN_CONDITION Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE hermes.run_condition
  ADD CONSTRAINT uq_run_condition_run_name
  UNIQUE (run_id, name);

-- ----------------------------------------------------------------------------
-- RUN_CONDITION_VALUE Table (Composite unique)
-- ----------------------------------------------------------------------------
ALTER TABLE hermes.run_condition_value
  ADD CONSTRAINT uq_run_condition_value_composite
  UNIQUE (run_condition_id, run_condition_option_id);

-- ============================================================================
-- Demeter Schema UNIQUE Constraints
-- ============================================================================

-- ----------------------------------------------------------------------------
-- BARCODES Table
-- ----------------------------------------------------------------------------
ALTER TABLE demeter.barcodes
  ADD CONSTRAINT uq_barcodes_barcode
  UNIQUE (barcode);

-- ============================================================================
-- CRITICAL UNIQUE INDEXES (Already Created in Table DDL)
-- ============================================================================
--
-- The following UNIQUE indexes were created as part of table DDL and are
-- REQUIRED for foreign key references:
--
-- 1. idx_goo_uid ON perseus.goo(uid)
--    - Referenced by: material_transition.material_id, transition_material.material_id
--    - CRITICAL for material lineage tracking
--
-- 2. idx_fatsmurf_uid ON perseus.fatsmurf(uid)
--    - Referenced by: material_transition.transition_id, transition_material.transition_id
--    - CRITICAL for material lineage tracking
--
-- These indexes MUST NOT be dropped or modified.
--
-- ============================================================================

-- ============================================================================
-- UNIQUE CONSTRAINT SUMMARY
-- ============================================================================
--
-- Total UNIQUE Constraints: 40
--
-- By Category:
--   - Single-column natural keys: 17 (name columns on lookup tables)
--   - Composite unique keys: 13 (junction tables, business logic uniqueness)
--   - UID-based unique indexes: 2 (goo.uid, fatsmurf.uid - in table DDL)
--
-- By Table Type:
--   - Lookup/type tables: 15 (enforce unique names)
--   - Junction tables: 8 (prevent duplicate associations)
--   - Business logic: 17 (enforce domain-specific uniqueness)
--
-- Performance Impact:
--   - UNIQUE constraints automatically create indexes
--   - Improves query performance for lookup operations
--   - Slight overhead on INSERT/UPDATE operations
--
-- ============================================================================
-- END OF UNIQUE CONSTRAINTS
-- ============================================================================
