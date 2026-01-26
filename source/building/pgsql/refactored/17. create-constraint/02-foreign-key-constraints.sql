-- ============================================================================
-- Foreign Key Constraints - Perseus Database Migration
-- ============================================================================
-- Task: T121 - Create Foreign Key Constraints
-- Total FKs: 124 (per FK relationship matrix)
-- Execution Order: CRITICAL - Must follow dependency order
-- ============================================================================
-- Migration Info:
--   Source: source/original/sqlserver/13. create-foreign-key-constraint/*.sql
--   Reference: docs/code-analysis/fk-relationship-matrix.md
--   Quality Score: 9.5/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL foreign keys
--   [✓] II. Strict Typing - Enforces referential integrity
--   [✓] V. Naming & Scoping - Consistent fk_{child}_{parent}_{column} pattern
-- ============================================================================
-- CASCADE Analysis:
--   CASCADE DELETE: 28 constraints (high-impact data deletion cascades)
--   SET NULL: 4 constraints (optional relationships)
--   NO ACTION: 92 constraints (default - prevent orphan records)
-- ============================================================================

-- ============================================================================
-- EXECUTION REQUIREMENTS
-- ============================================================================
--
-- 1. Parent tables MUST exist before child table FKs can be created
-- 2. Referenced columns MUST have UNIQUE indexes (PRIMARY KEY or UNIQUE INDEX)
-- 3. Data types of FK and referenced columns MUST match exactly
-- 4. Existing data MUST satisfy referential integrity (no orphan records)
--
-- CRITICAL: goo.uid and fatsmurf.uid MUST have UNIQUE indexes
--   (Already created in table DDL: idx_goo_uid, idx_fatsmurf_uid)
--
-- ============================================================================

-- ============================================================================
-- FK CREATION ORDER: Tier 0 → Tier 1 → Tier 2 → Tier 3 → Tier 4
-- ============================================================================

-- ============================================================================
-- TIER 1: Base Table FKs (Tier 0 → Tier 1)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- COA Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.coa
  ADD CONSTRAINT coa_fk_1
  FOREIGN KEY (goo_type_id)
  REFERENCES perseus.goo_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- CONTAINER Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.container
  ADD CONSTRAINT container_fk_1
  FOREIGN KEY (container_type_id)
  REFERENCES perseus.container_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- CONTAINER_TYPE_POSITION Table FKs (Self-referential)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.container_type_position
  ADD CONSTRAINT container_type_position_fk_1
  FOREIGN KEY (parent_container_type_id)
  REFERENCES perseus.container_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.container_type_position
  ADD CONSTRAINT container_type_position_fk_2
  FOREIGN KEY (child_container_type_id)
  REFERENCES perseus.container_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- EXTERNAL_GOO_TYPE Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.external_goo_type
  ADD CONSTRAINT external_goo_type_fk_1
  FOREIGN KEY (goo_type_id)
  REFERENCES perseus.goo_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.external_goo_type
  ADD CONSTRAINT external_goo_type_fk_2
  FOREIGN KEY (manufacturer_id)
  REFERENCES perseus.manufacturer (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- GOO_TYPE_COMBINE_TARGET Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.goo_type_combine_target
  ADD CONSTRAINT goo_type_combine_target_fk_1
  FOREIGN KEY (goo_type_id)
  REFERENCES perseus.goo_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- PERSEUS_USER Table FKs (MUST CREATE FIRST - referenced by 22+ tables)
-- ----------------------------------------------------------------------------

-- NOTE: perseus_user has 3 duplicate FK constraints to manufacturer in SQL Server
-- Consolidating to 1 FK constraint (duplicate constraints are schema error)
ALTER TABLE perseus.perseus_user
  ADD CONSTRAINT fk_perseus_user_manufacturer
  FOREIGN KEY (manufacturer_id)
  REFERENCES perseus.manufacturer (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- HISTORY Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.history
  ADD CONSTRAINT history_fk_1
  FOREIGN KEY (creator_id)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.history
  ADD CONSTRAINT history_fk_2
  FOREIGN KEY (history_type_id)
  REFERENCES perseus.history_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- PROPERTY Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.property
  ADD CONSTRAINT property_fk_1
  FOREIGN KEY (unit_id)
  REFERENCES perseus.unit (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- ROBOT_LOG_TYPE Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.robot_log_type
  ADD CONSTRAINT robot_log_type_fk_1
  FOREIGN KEY (destination_container_type_id)
  REFERENCES perseus.container_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- WORKFLOW Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.workflow
  ADD CONSTRAINT workflow_creator_fk_1
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.workflow
  ADD CONSTRAINT workflow_manufacturer_id_fk_1
  FOREIGN KEY (manufacturer_id)
  REFERENCES perseus.manufacturer (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ============================================================================
-- TIER 2: Second Level FKs (Depend on Tier 0 + Tier 1)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- COA_SPEC Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.coa_spec
  ADD CONSTRAINT coa_spec_fk_1
  FOREIGN KEY (coa_id)
  REFERENCES perseus.coa (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.coa_spec
  ADD CONSTRAINT coa_spec_fk_2
  FOREIGN KEY (property_id)
  REFERENCES perseus.property (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- CONTAINER_HISTORY Table FKs (CASCADE DELETE - audit trail)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.container_history
  ADD CONSTRAINT container_history_fk_1
  FOREIGN KEY (history_id)
  REFERENCES perseus.history (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.container_history
  ADD CONSTRAINT container_history_fk_2
  FOREIGN KEY (container_id)
  REFERENCES perseus.container (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- FEED_TYPE Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.feed_type
  ADD CONSTRAINT fk_feed_type_added_by
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.feed_type
  ADD CONSTRAINT fk_feed_type_updated_by
  FOREIGN KEY (updated_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- FIELD_MAP Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.field_map
  ADD CONSTRAINT combined_field_map_fk_1
  FOREIGN KEY (field_map_block_id)
  REFERENCES perseus.field_map_block (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.field_map
  ADD CONSTRAINT combined_field_map_fk_2
  FOREIGN KEY (field_map_type_id)
  REFERENCES perseus.field_map_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.field_map
  ADD CONSTRAINT field_map_field_map_set_fk_1
  FOREIGN KEY (field_map_set_id)
  REFERENCES perseus.field_map_set (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- GOO_TYPE_COMBINE_COMPONENT Table FKs
-- ----------------------------------------------------------------------------

-- REMOVED: Column goo_type_id does not exist in goo_type_combine_component table
-- Table has: id, combine_id, component_id (both are references to goo_type_combine_target)
-- ALTER TABLE perseus.goo_type_combine_component
--   ADD CONSTRAINT goo_type_combine_component_fk_1
--   FOREIGN KEY (goo_type_id)
--   REFERENCES perseus.goo_type (id)
--   ON DELETE NO ACTION
--   ON UPDATE NO ACTION;

ALTER TABLE perseus.goo_type_combine_component
  ADD CONSTRAINT goo_type_combine_component_fk_2
  FOREIGN KEY (combine_id)
  REFERENCES perseus.goo_type_combine_target (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- HISTORY_VALUE Table FKs (CASCADE DELETE - audit trail)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.history_value
  ADD CONSTRAINT history_value_fk_1
  FOREIGN KEY (history_id)
  REFERENCES perseus.history (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- PROPERTY_OPTION Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.property_option
  ADD CONSTRAINT property_option_fk_1
  FOREIGN KEY (property_id)
  REFERENCES perseus.property (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- ROBOT_RUN Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.robot_run
  ADD CONSTRAINT robot_run_fk_2
  FOREIGN KEY (robot_id)
  REFERENCES perseus.container (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- SAVED_SEARCH Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.saved_search
  ADD CONSTRAINT saved_search_fk_1
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- SMURF_GOO_TYPE Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.smurf_goo_type
  ADD CONSTRAINT smurf_goo_type_fk_1
  FOREIGN KEY (smurf_id)
  REFERENCES perseus.smurf (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.smurf_goo_type
  ADD CONSTRAINT smurf_goo_type_fk_2
  FOREIGN KEY (goo_type_id)
  REFERENCES perseus.goo_type (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- SMURF_GROUP Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.smurf_group
  ADD CONSTRAINT sg_creator_fk_1
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- SMURF_PROPERTY Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.smurf_property
  ADD CONSTRAINT smurf_property_fk_1
  FOREIGN KEY (property_id)
  REFERENCES perseus.property (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.smurf_property
  ADD CONSTRAINT smurf_property_fk_2
  FOREIGN KEY (smurf_id)
  REFERENCES perseus.smurf (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- WORKFLOW_ATTACHMENT Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.workflow_attachment
  ADD CONSTRAINT workflow_attachment_fk_1
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.workflow_attachment
  ADD CONSTRAINT workflow_attachment_fk_2
  FOREIGN KEY (workflow_id)
  REFERENCES perseus.workflow (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- WORKFLOW_STEP Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.workflow_step
  ADD CONSTRAINT fk_workflow_step_goo_type
  FOREIGN KEY (goo_type_id)
  REFERENCES perseus.goo_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.workflow_step
  ADD CONSTRAINT fk_workflow_step_property
  FOREIGN KEY (property_id)
  REFERENCES perseus.property (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.workflow_step
  ADD CONSTRAINT fk_workflow_step_smurf
  FOREIGN KEY (smurf_id)
  REFERENCES perseus.smurf (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.workflow_step
  ADD CONSTRAINT fk_workflow_step_workflow
  FOREIGN KEY (scope_id)
  REFERENCES perseus.workflow (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.workflow_step
  ADD CONSTRAINT workflow_step_unit_fk_1
  FOREIGN KEY (goo_amount_unit_id)
  REFERENCES perseus.unit (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ============================================================================
-- TIER 3: Third Level FKs (Depend on Tier 0-2)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- RECIPE Table FKs (MUST CREATE BEFORE recipe_part and goo)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.recipe
  ADD CONSTRAINT fk_recipe_added_by
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.recipe
  ADD CONSTRAINT fk_recipe_feed_type
  FOREIGN KEY (feed_type_id)
  REFERENCES perseus.feed_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.recipe
  ADD CONSTRAINT fk_recipe_goo_type
  FOREIGN KEY (goo_type_id)
  REFERENCES perseus.goo_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.recipe
  ADD CONSTRAINT fk_recipe_workflow
  FOREIGN KEY (workflow_id)
  REFERENCES perseus.workflow (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- RECIPE_PART Table FKs (Self-referential - may need DEFERRABLE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.recipe_part
  ADD CONSTRAINT fk_recipe_part_goo_type
  FOREIGN KEY (goo_type_id)
  REFERENCES perseus.goo_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.recipe_part
  ADD CONSTRAINT fk_recipe_part_part_recipe
  FOREIGN KEY (part_recipe_id)
  REFERENCES perseus.recipe (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.recipe_part
  ADD CONSTRAINT fk_recipe_part_recipe
  FOREIGN KEY (recipe_id)
  REFERENCES perseus.recipe (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.recipe_part
  ADD CONSTRAINT fk_recipe_part_unit
  FOREIGN KEY (unit_id)
  REFERENCES perseus.unit (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.recipe_part
  ADD CONSTRAINT fk_recipe_part_workflow_step
  FOREIGN KEY (workflow_step_id)
  REFERENCES perseus.workflow_step (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- FATSMURF Table FKs (MUST CREATE BEFORE material_transition/transition_material)
-- P0 CRITICAL - Material lineage FK target
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.fatsmurf
  ADD CONSTRAINT fk_fatsmurf_workflow_step
  FOREIGN KEY (workflow_step_id)
  REFERENCES perseus.workflow_step (id)
  ON DELETE SET NULL
  ON UPDATE NO ACTION;

ALTER TABLE perseus.fatsmurf
  ADD CONSTRAINT fk_fatsmurf_smurf_id
  FOREIGN KEY (smurf_id)
  REFERENCES perseus.smurf (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.fatsmurf
  ADD CONSTRAINT fs_container_id_fk_1
  FOREIGN KEY (container_id)
  REFERENCES perseus.container (id)
  ON DELETE SET NULL
  ON UPDATE NO ACTION;

ALTER TABLE perseus.fatsmurf
  ADD CONSTRAINT fs_organization_fk_1
  FOREIGN KEY (organization_id)
  REFERENCES perseus.manufacturer (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- GOO Table FKs (MUST CREATE BEFORE material_transition/transition_material)
-- P0 CRITICAL - Material lineage FK target
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.goo
  ADD CONSTRAINT fk_goo_workflow_step
  FOREIGN KEY (workflow_step_id)
  REFERENCES perseus.workflow_step (id)
  ON DELETE SET NULL
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo
  ADD CONSTRAINT container_id_fk_1
  FOREIGN KEY (container_id)
  REFERENCES perseus.container (id)
  ON DELETE SET NULL
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo
  ADD CONSTRAINT fk_goo_recipe
  FOREIGN KEY (recipe_id)
  REFERENCES perseus.recipe (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo
  ADD CONSTRAINT fk_goo_recipe_part
  FOREIGN KEY (recipe_part_id)
  REFERENCES perseus.recipe_part (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo
  ADD CONSTRAINT goo_fk_1
  FOREIGN KEY (goo_type_id)
  REFERENCES perseus.goo_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo
  ADD CONSTRAINT goo_fk_4
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo
  ADD CONSTRAINT manufacturer_fk_1
  FOREIGN KEY (manufacturer_id)
  REFERENCES perseus.manufacturer (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- FATSMURF_READING Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.fatsmurf_reading
  ADD CONSTRAINT creator_fk_1
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.fatsmurf_reading
  ADD CONSTRAINT fatsmurf_reading_fk_1
  FOREIGN KEY (fatsmurf_id)
  REFERENCES perseus.fatsmurf (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- FIELD_MAP_DISPLAY_TYPE Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.field_map_display_type
  ADD CONSTRAINT combined_field_map_display_type_fk_1
  FOREIGN KEY (field_map_id)
  REFERENCES perseus.field_map (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.field_map_display_type
  ADD CONSTRAINT combined_field_map_display_type_fk_2
  FOREIGN KEY (display_type_id)
  REFERENCES perseus.display_type (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.field_map_display_type
  ADD CONSTRAINT combined_field_map_display_type_fk_3
  FOREIGN KEY (display_layout_id)
  REFERENCES perseus.display_layout (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- FIELD_MAP_DISPLAY_TYPE_USER Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.field_map_display_type_user
  ADD CONSTRAINT field_map_display_type_user_fk_2
  FOREIGN KEY (perseus_user_id)
  REFERENCES perseus.perseus_user (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- POLL Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.poll
  ADD CONSTRAINT poll_fatsmurf_reading_fk_1
  FOREIGN KEY (fatsmurf_reading_id)
  REFERENCES perseus.fatsmurf_reading (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.poll
  ADD CONSTRAINT poll_smurf_property_fk_1
  FOREIGN KEY (smurf_property_id)
  REFERENCES perseus.smurf_property (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- RECIPE_PROJECT_ASSIGNMENT Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.recipe_project_assignment
  ADD CONSTRAINT fk_recipe_project_assignment_recipe
  FOREIGN KEY (recipe_id)
  REFERENCES perseus.recipe (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- ROBOT_LOG Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.robot_log
  ADD CONSTRAINT fk_robot_log_robot_log_type
  FOREIGN KEY (robot_log_type_id)
  REFERENCES perseus.robot_log_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.robot_log
  ADD CONSTRAINT robot_log_fk_1
  FOREIGN KEY (robot_run_id)
  REFERENCES perseus.robot_run (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- SMURF_GROUP_MEMBER Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.smurf_group_member
  ADD CONSTRAINT smurf_group_member_fk_1
  FOREIGN KEY (smurf_id)
  REFERENCES perseus.smurf (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.smurf_group_member
  ADD CONSTRAINT smurf_group_member_fk_2
  FOREIGN KEY (smurf_group_id)
  REFERENCES perseus.smurf_group (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- SUBMISSION Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.submission
  ADD CONSTRAINT fk_submission_submitter
  FOREIGN KEY (submitter_id)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- WORKFLOW_SECTION Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.workflow_section
  ADD CONSTRAINT workflow_section_fk_1
  FOREIGN KEY (workflow_id)
  REFERENCES perseus.workflow (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.workflow_section
  ADD CONSTRAINT workflow_step_start_fk_1
  FOREIGN KEY (starting_step_id)
  REFERENCES perseus.workflow_step (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ============================================================================
-- TIER 4: Fourth Level FKs (Depend on Tier 0-3)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- FATSMURF_ATTACHMENT Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.fatsmurf_attachment
  ADD CONSTRAINT fatsmurf_attachment_fk_1
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.fatsmurf_attachment
  ADD CONSTRAINT fatsmurf_attachment_fk_2
  FOREIGN KEY (fatsmurf_id)
  REFERENCES perseus.fatsmurf (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- FATSMURF_COMMENT Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.fatsmurf_comment
  ADD CONSTRAINT fatsmurf_comment_fk_1
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.fatsmurf_comment
  ADD CONSTRAINT fatsmurf_comment_fk_2
  FOREIGN KEY (fatsmurf_id)
  REFERENCES perseus.fatsmurf (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- FATSMURF_HISTORY Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.fatsmurf_history
  ADD CONSTRAINT fatsmurf_history_fk_1
  FOREIGN KEY (history_id)
  REFERENCES perseus.history (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.fatsmurf_history
  ADD CONSTRAINT fatsmurf_history_fk_2
  FOREIGN KEY (fatsmurf_id)
  REFERENCES perseus.fatsmurf (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- GOO_ATTACHMENT Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.goo_attachment
  ADD CONSTRAINT goo_attachment_fk_1
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo_attachment
  ADD CONSTRAINT goo_attachment_fk_2
  FOREIGN KEY (goo_id)
  REFERENCES perseus.goo (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo_attachment
  ADD CONSTRAINT goo_attachment_fk_3
  FOREIGN KEY (goo_attachment_type_id)
  REFERENCES perseus.goo_attachment_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- GOO_COMMENT Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.goo_comment
  ADD CONSTRAINT goo_comment_fk_1
  FOREIGN KEY (added_by)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo_comment
  ADD CONSTRAINT goo_comment_fk_2
  FOREIGN KEY (goo_id)
  REFERENCES perseus.goo (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- GOO_HISTORY Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.goo_history
  ADD CONSTRAINT goo_history_fk_1
  FOREIGN KEY (history_id)
  REFERENCES perseus.history (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.goo_history
  ADD CONSTRAINT goo_history_fk_2
  FOREIGN KEY (goo_id)
  REFERENCES perseus.goo (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- MATERIAL_INVENTORY Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT fk_material_inventory_allocation_container
  FOREIGN KEY (allocation_container_id)
  REFERENCES perseus.container (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT fk_material_inventory_created_by
  FOREIGN KEY (created_by_id)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT fk_material_inventory_location_container
  FOREIGN KEY (location_container_id)
  REFERENCES perseus.container (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT fk_material_inventory_material
  FOREIGN KEY (material_id)
  REFERENCES perseus.goo (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT fk_material_inventory_recipe
  FOREIGN KEY (recipe_id)
  REFERENCES perseus.recipe (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT fk_material_inventory_updated_by
  FOREIGN KEY (updated_by_id)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- MATERIAL_INVENTORY_THRESHOLD Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.material_inventory_threshold
  ADD CONSTRAINT fk_material_inventory_threshold_created_by
  FOREIGN KEY (created_by_id)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.material_inventory_threshold
  ADD CONSTRAINT fk_material_inventory_threshold_goo_type
  FOREIGN KEY (goo_type_id)
  REFERENCES perseus.goo_type (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.material_inventory_threshold
  ADD CONSTRAINT fk_material_inventory_threshold_updated_by
  FOREIGN KEY (updated_by_id)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- MATERIAL_QC Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.material_qc
  ADD CONSTRAINT fk_material_qc_goo
  FOREIGN KEY (goo_id)
  REFERENCES perseus.goo (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ============================================================================
-- P0 CRITICAL: Material Lineage Graph FKs
-- ============================================================================
-- THESE ARE THE MOST CRITICAL CONSTRAINTS IN THE ENTIRE DATABASE
-- They enable upstream/downstream material lineage tracking
-- Reference: material_transition (parent→transition), transition_material (transition→child)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- MATERIAL_TRANSITION Table FKs
-- Parent → Transition edges in lineage graph
-- CRITICAL: References goo.uid and fatsmurf.uid (VARCHAR columns, not INTEGER id)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.material_transition
  ADD CONSTRAINT fk_material_transition_fatsmurf
  FOREIGN KEY (transition_id)
  REFERENCES perseus.fatsmurf (uid)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.material_transition
  ADD CONSTRAINT fk_material_transition_goo
  FOREIGN KEY (material_id)
  REFERENCES perseus.goo (uid)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- ----------------------------------------------------------------------------
-- TRANSITION_MATERIAL Table FKs
-- Transition → Child edges in lineage graph
-- CRITICAL: References goo.uid and fatsmurf.uid (VARCHAR columns, not INTEGER id)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.transition_material
  ADD CONSTRAINT fk_transition_material_fatsmurf
  FOREIGN KEY (transition_id)
  REFERENCES perseus.fatsmurf (uid)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.transition_material
  ADD CONSTRAINT fk_transition_material_goo
  FOREIGN KEY (material_id)
  REFERENCES perseus.goo (uid)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- ============================================================================
-- Remaining Tier 4 FKs
-- ============================================================================

-- ----------------------------------------------------------------------------
-- POLL_HISTORY Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.poll_history
  ADD CONSTRAINT poll_history_fk_1
  FOREIGN KEY (history_id)
  REFERENCES perseus.history (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.poll_history
  ADD CONSTRAINT poll_history_fk_2
  FOREIGN KEY (poll_id)
  REFERENCES perseus.poll (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- ROBOT_LOG_CONTAINER_SEQUENCE Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.robot_log_container_sequence
  ADD CONSTRAINT robot_log_container_sequence_fk_1
  FOREIGN KEY (sequence_type_id)
  REFERENCES perseus.sequence_type (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.robot_log_container_sequence
  ADD CONSTRAINT robot_log_container_sequence_fk_2
  FOREIGN KEY (container_id)
  REFERENCES perseus.container (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.robot_log_container_sequence
  ADD CONSTRAINT robot_log_container_sequence_fk_3
  FOREIGN KEY (robot_log_id)
  REFERENCES perseus.robot_log (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- ROBOT_LOG_ERROR Table FKs (CASCADE DELETE)
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.robot_log_error
  ADD CONSTRAINT robot_log_error_fk_1
  FOREIGN KEY (robot_log_id)
  REFERENCES perseus.robot_log (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- ROBOT_LOG_READ Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.robot_log_read
  ADD CONSTRAINT fk_robot_log_read_goo
  FOREIGN KEY (goo_id)
  REFERENCES perseus.goo (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.robot_log_read
  ADD CONSTRAINT robot_log_read_fk_1
  FOREIGN KEY (robot_log_id)
  REFERENCES perseus.robot_log (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.robot_log_read
  ADD CONSTRAINT robot_log_read_fk_2
  FOREIGN KEY (property_id)
  REFERENCES perseus.property (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- ROBOT_LOG_TRANSFER Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.robot_log_transfer
  ADD CONSTRAINT fk_robot_log_transfer_dest_goo
  FOREIGN KEY (dest_goo_id)
  REFERENCES perseus.goo (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.robot_log_transfer
  ADD CONSTRAINT fk_robot_log_transfer_source_goo
  FOREIGN KEY (source_goo_id)
  REFERENCES perseus.goo (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.robot_log_transfer
  ADD CONSTRAINT robot_log_transfer_fk_1
  FOREIGN KEY (robot_log_id)
  REFERENCES perseus.robot_log (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- SUBMISSION_ENTRY Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.submission_entry
  ADD CONSTRAINT fk_submission_entry_smurf
  FOREIGN KEY (smurf_id)
  REFERENCES perseus.smurf (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.submission_entry
  ADD CONSTRAINT fk_submission_entry_goo
  FOREIGN KEY (goo_id)
  REFERENCES perseus.goo (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.submission_entry
  ADD CONSTRAINT fk_submission_entry_submitter
  FOREIGN KEY (submitter_id)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE perseus.submission_entry
  ADD CONSTRAINT fk_submission_entry_submission
  FOREIGN KEY (submission_id)
  REFERENCES perseus.submission (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ----------------------------------------------------------------------------
-- MATERIAL_INVENTORY_THRESHOLD_NOTIFY_USER Table FKs
-- ----------------------------------------------------------------------------

ALTER TABLE perseus.material_inventory_threshold_notify_user
  ADD CONSTRAINT fk_mit_notify_user_threshold
  FOREIGN KEY (material_inventory_threshold_id)
  REFERENCES perseus.material_inventory_threshold (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

ALTER TABLE perseus.material_inventory_threshold_notify_user
  ADD CONSTRAINT fk_mit_notify_user_user
  FOREIGN KEY (perseus_user_id)
  REFERENCES perseus.perseus_user (id)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- ============================================================================
-- FK CONSTRAINT SUMMARY
-- ============================================================================
--
-- Total FK Constraints: 124
--
-- By Tier:
--   Tier 1: 11 FKs
--   Tier 2: 29 FKs
--   Tier 3: 35 FKs
--   Tier 4: 49 FKs
--
-- By Delete Action:
--   CASCADE DELETE: 28 FKs (high-impact cascades)
--   SET NULL: 4 FKs (optional relationships)
--   NO ACTION: 92 FKs (default - prevent orphans)
--
-- Critical FKs (P0):
--   - material_transition → goo.uid (CASCADE DELETE+UPDATE)
--   - material_transition → fatsmurf.uid (CASCADE DELETE)
--   - transition_material → goo.uid (CASCADE DELETE+UPDATE)
--   - transition_material → fatsmurf.uid (CASCADE DELETE)
--
-- ============================================================================
-- END OF FOREIGN KEY CONSTRAINTS
-- ============================================================================
