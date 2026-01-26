# Foreign Key Relationship Matrix - Perseus Database Migration

## Executive Summary

**Total FK Constraints:** 124
**Tables with FKs:** 63 (out of 101 total)
**Tables without FKs:** 38 (Tier 0 base tables)
**CASCADE DELETE Constraints:** 28
**SET NULL Constraints:** 4
**Default (NO ACTION):** 92

---

## Complete FK Constraint Matrix

### Sorted by Child Table (Alphabetical)

| # | Child Table | Parent Table | FK Column | Referenced Column | On Delete | On Update | Constraint Name |
|---|-------------|--------------|-----------|-------------------|-----------|-----------|-----------------|
| 1 | coa | goo_type | goo_type_id | id | NO ACTION | NO ACTION | coa_FK_1 |
| 2 | coa_spec | coa | coa_id | id | NO ACTION | NO ACTION | coa_spec_FK_1 |
| 3 | coa_spec | property | property_id | id | NO ACTION | NO ACTION | coa_spec_FK_2 |
| 4 | container | container_type | container_type_id | id | NO ACTION | NO ACTION | container_FK_1 |
| 5 | container_history | history | history_id | id | CASCADE | NO ACTION | container_history_FK_1 |
| 6 | container_history | container | container_id | id | CASCADE | NO ACTION | container_history_FK_2 |
| 7 | container_type_position | container_type | parent_container_type_id | id | NO ACTION | NO ACTION | container_type_position_FK_1 |
| 8 | container_type_position | container_type | child_container_type_id | id | NO ACTION | NO ACTION | container_type_position_FK_2 |
| 9 | external_goo_type | goo_type | goo_type_id | id | NO ACTION | NO ACTION | external_goo_type_FK_1 |
| 10 | external_goo_type | manufacturer | manufacturer_id | id | NO ACTION | NO ACTION | external_goo_type_FK_2 |
| 11 | fatsmurf | workflow_step | workflow_step_id | id | SET NULL | NO ACTION | FK_fatsmurf_workflow_step |
| 12 | fatsmurf | smurf | smurf_id | id | NO ACTION | NO ACTION | fk_fatsmurf_smurf_id |
| 13 | fatsmurf | container | container_id | id | SET NULL | NO ACTION | fs_container_id_FK_1 |
| 14 | fatsmurf | manufacturer | organization_id | id | NO ACTION | NO ACTION | fs_organization_FK_1 |
| 15 | fatsmurf_attachment | perseus_user | added_by | id | NO ACTION | NO ACTION | fatsmurf_attachment_FK_1 |
| 16 | fatsmurf_attachment | fatsmurf | fatsmurf_id | id | CASCADE | NO ACTION | fatsmurf_attachment_FK_2 |
| 17 | fatsmurf_comment | perseus_user | added_by | id | NO ACTION | NO ACTION | fatsmurf_comment_FK_1 |
| 18 | fatsmurf_comment | fatsmurf | fatsmurf_id | id | CASCADE | NO ACTION | fatsmurf_comment_FK_2 |
| 19 | fatsmurf_history | history | history_id | id | CASCADE | NO ACTION | fatsmurf_history_FK_1 |
| 20 | fatsmurf_history | fatsmurf | fatsmurf_id | id | CASCADE | NO ACTION | fatsmurf_history_FK_2 |
| 21 | fatsmurf_reading | perseus_user | added_by | id | NO ACTION | NO ACTION | creator_FK_1 |
| 22 | fatsmurf_reading | fatsmurf | fatsmurf_id | id | CASCADE | NO ACTION | fatsmurf_reading_FK_1 |
| 23 | feed_type | perseus_user | added_by | id | NO ACTION | NO ACTION | FK__feed_type__creat__5F28586B |
| 24 | feed_type | perseus_user | updated_by_id | id | NO ACTION | NO ACTION | FK__feed_type__updat__601C7CA4 |
| 25 | field_map | field_map_block | field_map_block_id | id | NO ACTION | NO ACTION | combined_field_map_FK_1 |
| 26 | field_map | field_map_type | field_map_type_id | id | NO ACTION | NO ACTION | combined_field_map_FK_2 |
| 27 | field_map | field_map_set | field_map_set_id | id | NO ACTION | NO ACTION | field_map_field_map_set_FK_1 |
| 28 | field_map_display_type | field_map | field_map_id | id | CASCADE | NO ACTION | combined_field_map_display_type_FK_1 |
| 29 | field_map_display_type | display_type | display_type_id | id | CASCADE | NO ACTION | combined_field_map_display_type_FK_2 |
| 30 | field_map_display_type | display_layout | display_layout_id | id | CASCADE | NO ACTION | combined_field_map_display_type_FK_3 |
| 31 | field_map_display_type_user | perseus_user | user_id | id | CASCADE | NO ACTION | field_map_display_type_user_FK_2 |
| 32 | goo | workflow_step | workflow_step_id | id | SET NULL | NO ACTION | FK_goo_workflow_step |
| 33 | goo | container | container_id | id | SET NULL | NO ACTION | container_id_FK_1 |
| 34 | goo | recipe | recipe_id | id | NO ACTION | NO ACTION | fk_goo_recipe |
| 35 | goo | recipe_part | recipe_part_id | id | NO ACTION | NO ACTION | fk_goo_recipe_part |
| 36 | goo | goo_type | goo_type_id | id | NO ACTION | NO ACTION | goo_FK_1 |
| 37 | goo | perseus_user | added_by | id | NO ACTION | NO ACTION | goo_FK_4 |
| 38 | goo | manufacturer | manufacturer_id | id | NO ACTION | NO ACTION | manufacturer_FK_1 |
| 39 | goo_attachment | perseus_user | added_by | id | NO ACTION | NO ACTION | goo_attachment_FK_1 |
| 40 | goo_attachment | goo | goo_id | id | CASCADE | NO ACTION | goo_attachment_FK_2 |
| 41 | goo_attachment | goo_attachment_type | goo_attachment_type_id | id | NO ACTION | NO ACTION | goo_attachment_FK_3 |
| 42 | goo_comment | perseus_user | added_by | id | NO ACTION | NO ACTION | goo_comment_FK_1 |
| 43 | goo_comment | goo | goo_id | id | CASCADE | NO ACTION | goo_comment_FK_2 |
| 44 | goo_history | history | history_id | id | CASCADE | NO ACTION | goo_history_FK_1 |
| 45 | goo_history | goo | goo_id | id | CASCADE | NO ACTION | goo_history_FK_2 |
| 46 | goo_type_combine_component | goo_type | goo_type_id | id | NO ACTION | NO ACTION | goo_type_combine_component_FK_1 |
| 47 | goo_type_combine_component | goo_type_combine_target | goo_type_combine_target_id | id | CASCADE | NO ACTION | goo_type_combine_component_FK_2 |
| 48 | goo_type_combine_target | goo_type | goo_type_id | id | NO ACTION | NO ACTION | goo_type_combine_target_FK_1 |
| 49 | history | perseus_user | creator_id | id | NO ACTION | NO ACTION | history_FK_1 |
| 50 | history | history_type | history_type_id | id | NO ACTION | NO ACTION | history_FK_2 |
| 51 | history_value | history | history_id | id | CASCADE | NO ACTION | history_value_FK_1 |
| 52 | material_inventory | container | allocation_container_id | id | NO ACTION | NO ACTION | FK__material___alloc__1642B7D4 |
| 53 | material_inventory | perseus_user | created_by_id | id | NO ACTION | NO ACTION | FK__material___creat__1A1348B8 |
| 54 | material_inventory | container | location_container_id | id | NO ACTION | NO ACTION | FK__material___locat__191F247F |
| 55 | material_inventory | goo | material_id | id | NO ACTION | NO ACTION | FK__material___mater__182B0046 |
| 56 | material_inventory | recipe | recipe_id | id | NO ACTION | NO ACTION | FK__material___recip__1736DC0D |
| 57 | material_inventory | perseus_user | updated_by_id | id | NO ACTION | NO ACTION | FK__material___updat__1B076CF1 |
| 58 | material_inventory_threshold | perseus_user | created_by_id | id | NO ACTION | NO ACTION | FK_material_inventory_threshold_created_by |
| 59 | material_inventory_threshold | goo_type | material_type_id | id | NO ACTION | NO ACTION | FK_material_inventory_threshold_material_type |
| 60 | material_inventory_threshold | perseus_user | updated_by_id | id | NO ACTION | NO ACTION | FK_material_inventory_threshold_updated_by |
| 61 | material_inventory_threshold_notify_user | material_inventory_threshold | threshold_id | id | CASCADE | NO ACTION | FK_mit_notify_user_threshold |
| 62 | material_inventory_threshold_notify_user | perseus_user | user_id | id | NO ACTION | NO ACTION | FK_mit_notify_user_user |
| 63 | material_qc | goo | material_id | id | NO ACTION | NO ACTION | FK__material___mater__5B988A00 |
| 64 | **material_transition** | **fatsmurf** | transition_id | **uid** | **CASCADE** | NO ACTION | FK_material_transition_fatsmurf |
| 65 | **material_transition** | **goo** | material_id | **uid** | **CASCADE** | **CASCADE** | FK_material_transition_goo |
| 66 | perseus_user | manufacturer | manufacturer_id | id | NO ACTION | NO ACTION | FK__perseus_u__manuf__5B3C942F |
| 67 | perseus_user | manufacturer | manufacturer_id | id | NO ACTION | NO ACTION | FK__perseus_u__manuf__5E1900DA |
| 68 | perseus_user | manufacturer | manufacturer_id | id | NO ACTION | NO ACTION | FK__perseus_u__manuf__6001494C |
| 69 | poll | fatsmurf_reading | fatsmurf_reading_id | id | CASCADE | NO ACTION | poll_fatsmurf_reading_FK_1 |
| 70 | poll | smurf_property | smurf_property_id | id | NO ACTION | NO ACTION | poll_smurf_property_FK_1 |
| 71 | poll_history | history | history_id | id | CASCADE | NO ACTION | poll_history_FK_1 |
| 72 | poll_history | poll | poll_id | id | CASCADE | NO ACTION | poll_history_FK_2 |
| 73 | property | unit | unit_id | id | NO ACTION | NO ACTION | property_FK_1 |
| 74 | property_option | property | property_id | id | NO ACTION | NO ACTION | property_option_FK_1 |
| 75 | recipe | perseus_user | added_by | id | NO ACTION | NO ACTION | FK__recipe__added_by__659E8358 |
| 76 | recipe | feed_type | feed_type_id | id | NO ACTION | NO ACTION | FK__recipe__feed_typ__471BC4B0 |
| 77 | recipe | goo_type | goo_type_id | id | NO ACTION | NO ACTION | FK__recipe__goo_type__6692A791 |
| 78 | recipe | workflow | workflow_id | id | NO ACTION | NO ACTION | FK__recipe__workflow__64AA5F1F |
| 79 | recipe_part | goo_type | goo_type_id | id | NO ACTION | NO ACTION | FK__recipe_pa__goo_t__6E33C959 |
| 80 | recipe_part | recipe | part_recipe_id | id | NO ACTION | NO ACTION | FK__recipe_pa__part___083EB140 |
| 81 | recipe_part | recipe | recipe_id | id | NO ACTION | NO ACTION | FK__recipe_pa__recip__6D3FA520 |
| 82 | recipe_part | unit | unit_id | id | NO ACTION | NO ACTION | FK__recipe_pa__unit___6B575CAE |
| 83 | recipe_part | workflow_step | workflow_step_id | id | NO ACTION | NO ACTION | FK__recipe_pa__workf__6C4B80E7 |
| 84 | recipe_project_assignment | recipe | recipe_id | id | NO ACTION | NO ACTION | FK__recipe_pr__recip__0D5F605D |
| 85 | robot_log | robot_log_type | robot_log_type_id | id | NO ACTION | NO ACTION | FK__robot_log__robot__01BF6602 |
| 86 | robot_log | robot_run | robot_run_id | id | NO ACTION | NO ACTION | robot_log_FK_1 |
| 87 | robot_log_container_sequence | sequence_type | sequence_type_id | id | CASCADE | NO ACTION | robot_log_container_sequence_FK_1 |
| 88 | robot_log_container_sequence | container | container_id | id | CASCADE | NO ACTION | robot_log_container_sequence_FK_2 |
| 89 | robot_log_container_sequence | robot_log | robot_log_id | id | CASCADE | NO ACTION | robot_log_container_sequence_FK_3 |
| 90 | robot_log_error | robot_log | robot_log_id | id | CASCADE | NO ACTION | robot_log_error_FK_1 |
| 91 | robot_log_read | goo | source_material_id | id | NO ACTION | NO ACTION | FK_robot_log_read_source_material_id |
| 92 | robot_log_read | robot_log | robot_log_id | id | CASCADE | NO ACTION | robot_log_read_FK_1 |
| 93 | robot_log_read | property | property_id | id | CASCADE | NO ACTION | robot_log_read_FK_2 |
| 94 | robot_log_transfer | goo | destination_material_id | id | NO ACTION | NO ACTION | FK_robot_log_transfer_destination_material_id |
| 95 | robot_log_transfer | goo | source_material_id | id | NO ACTION | NO ACTION | FK_robot_log_transfer_source_material_id |
| 96 | robot_log_transfer | robot_log | robot_log_id | id | CASCADE | NO ACTION | robot_log_transfer_FK_1 |
| 97 | robot_log_type | container_type | destination_container_type_id | id | NO ACTION | NO ACTION | robot_log_type_FK_1 |
| 98 | robot_run | container | robot_id | id | NO ACTION | NO ACTION | robot_run_FK_2 |
| 99 | saved_search | perseus_user | added_by | id | NO ACTION | NO ACTION | saved_search_FK_1 |
| 100 | smurf_goo_type | smurf | smurf_id | id | NO ACTION | NO ACTION | smurf_goo_type_FK_1 |
| 101 | smurf_goo_type | goo_type | goo_type_id | id | CASCADE | NO ACTION | smurf_goo_type_FK_2 |
| 102 | smurf_group | perseus_user | added_by | id | NO ACTION | NO ACTION | sg_creator_FK_1 |
| 103 | smurf_group_member | smurf | smurf_id | id | CASCADE | NO ACTION | smurf_group_member_FK_1 |
| 104 | smurf_group_member | smurf_group | smurf_group_id | id | CASCADE | NO ACTION | smurf_group_member_FK_2 |
| 105 | smurf_property | property | property_id | id | CASCADE | NO ACTION | smurf_property_FK_1 |
| 106 | smurf_property | smurf | smurf_id | id | CASCADE | NO ACTION | smurf_property_FK_2 |
| 107 | submission | perseus_user | submitter_id | id | NO ACTION | NO ACTION | FK__submissio__submi__739DC5E2 |
| 108 | submission_entry | smurf | assay_type_id | id | NO ACTION | NO ACTION | FK__submissio__assay__78627AFF |
| 109 | submission_entry | goo | material_id | id | NO ACTION | NO ACTION | FK__submissio__mater__79569F38 |
| 110 | submission_entry | perseus_user | prepped_by_id | id | NO ACTION | NO ACTION | FK__submissio__prepp__7D27301C |
| 111 | submission_entry | submission | submission_id | id | NO ACTION | NO ACTION | FK__submissio__submi__7C330BE3 |
| 112 | **transition_material** | **fatsmurf** | transition_id | **uid** | **CASCADE** | NO ACTION | FK_transition_material_fatsmurf |
| 113 | **transition_material** | **goo** | material_id | **uid** | **CASCADE** | **CASCADE** | FK_transition_material_goo |
| 114 | workflow | perseus_user | added_by | id | NO ACTION | NO ACTION | workflow_creator_FK_1 |
| 115 | workflow | manufacturer | manufacturer_id | id | NO ACTION | NO ACTION | workflow_manufacturer_id_FK_1 |
| 116 | workflow_attachment | perseus_user | added_by | id | NO ACTION | NO ACTION | workflow_attachment_FK_1 |
| 117 | workflow_attachment | workflow | workflow_id | id | CASCADE | NO ACTION | workflow_attachment_FK_2 |
| 118 | workflow_section | workflow | workflow_id | id | CASCADE | NO ACTION | workflow_section_FK_1 |
| 119 | workflow_section | workflow_step | starting_step_id | id | NO ACTION | NO ACTION | workflow_step_start_FK_1 |
| 120 | workflow_step | goo_type | goo_type_id | id | NO ACTION | NO ACTION | FK_workflow_step_goo_type |
| 121 | workflow_step | property | property_id | id | NO ACTION | NO ACTION | FK_workflow_step_property |
| 122 | workflow_step | smurf | smurf_id | id | NO ACTION | NO ACTION | FK_workflow_step_smurf |
| 123 | workflow_step | workflow | scope_id | id | CASCADE | NO ACTION | FK_workflow_step_workflow |
| 124 | workflow_step | unit | goo_amount_unit_id | id | NO ACTION | NO ACTION | workflow_step_unit_FK_1 |

---

## FK Constraints by Parent Table (Most Referenced)

| Parent Table | Child Tables | FK Count | Notes |
|--------------|--------------|----------|-------|
| **perseus_user** | 22 tables | 25 | Most referenced table |
| **goo** | 9 tables | 11 | Core material table |
| **goo_type** | 9 tables | 9 | Material type definitions |
| **fatsmurf** | 7 tables | 7 | Experiment/transition table |
| **workflow** | 4 tables | 4 | Workflow definitions |
| container | 7 tables | 7 | Container instances |
| manufacturer | 4 tables | 5 | Manufacturer records |
| history | 5 tables | 5 | Audit history |
| property | 4 tables | 5 | Property definitions |
| robot_log | 4 tables | 4 | Robot operation logs |
| smurf | 5 tables | 5 | Smurf definitions |
| container_type | 3 tables | 4 | Container types |
| recipe | 4 tables | 4 | Recipe definitions |
| workflow_step | 4 tables | 4 | Workflow steps |

---

## P0 Critical FK Relationships

### Material Lineage Graph FKs

| Constraint | Child Table | Parent Table | Column | Referenced | Cascade |
|------------|-------------|--------------|--------|------------|---------|
| FK_material_transition_goo | material_transition | goo | material_id | uid | DELETE+UPDATE |
| FK_material_transition_fatsmurf | material_transition | fatsmurf | transition_id | uid | DELETE |
| FK_transition_material_goo | transition_material | goo | material_id | uid | DELETE+UPDATE |
| FK_transition_material_fatsmurf | transition_material | fatsmurf | transition_id | uid | DELETE |

**CRITICAL**: These 4 FKs use `uid` (NVARCHAR/VARCHAR) columns as references, NOT integer IDs!

### Required Indexes for UID-Based FKs:

```sql
-- PostgreSQL: Create unique indexes on uid columns BEFORE FK creation
CREATE UNIQUE INDEX idx_goo_uid ON dbo.goo(uid);
CREATE UNIQUE INDEX idx_fatsmurf_uid ON dbo.fatsmurf(uid);
```

---

## CASCADE DELETE Impact Analysis

### High-Impact CASCADE Chains

**Chain 1: goo -> material_transition/transition_material**
```
DELETE FROM goo WHERE id = X
  -> CASCADE: material_transition (material_id = goo.uid)
  -> CASCADE: transition_material (material_id = goo.uid)
```
**Business Impact**: Deleting a material removes ALL lineage relationships!

**Chain 2: fatsmurf -> material_transition/transition_material**
```
DELETE FROM fatsmurf WHERE id = X
  -> CASCADE: material_transition (transition_id = fatsmurf.uid)
  -> CASCADE: transition_material (transition_id = fatsmurf.uid)
  -> CASCADE: fatsmurf_attachment
  -> CASCADE: fatsmurf_comment
  -> CASCADE: fatsmurf_history
  -> CASCADE: fatsmurf_reading
    -> CASCADE: poll (fatsmurf_reading_id)
      -> CASCADE: poll_history
```
**Business Impact**: Deleting an experiment removes ALL related data!

**Chain 3: workflow -> workflow_step/workflow_section**
```
DELETE FROM workflow WHERE id = X
  -> CASCADE: workflow_attachment
  -> CASCADE: workflow_section
  -> CASCADE: workflow_step
  -> SET NULL: fatsmurf.workflow_step_id
  -> SET NULL: goo.workflow_step_id
```

### Medium-Impact CASCADE Chains

**Chain 4: history -> *_history tables**
```
DELETE FROM history WHERE id = X
  -> CASCADE: container_history
  -> CASCADE: fatsmurf_history
  -> CASCADE: goo_history
  -> CASCADE: history_value
  -> CASCADE: poll_history
```

---

## Tables with Multiple FKs to Same Parent

| Child Table | Parent Table | FK Count | Columns |
|-------------|--------------|----------|---------|
| perseus_user | manufacturer | 3 | manufacturer_id (same column, 3 constraints!) |
| material_inventory | container | 2 | allocation_container_id, location_container_id |
| material_inventory | perseus_user | 2 | created_by_id, updated_by_id |
| material_inventory_threshold | perseus_user | 2 | created_by_id, updated_by_id |
| recipe_part | recipe | 2 | recipe_id, part_recipe_id |
| robot_log_transfer | goo | 2 | source_material_id, destination_material_id |
| container_type_position | container_type | 2 | parent_container_type_id, child_container_type_id |

**NOTE**: `perseus_user` has 3 identical FKs to `manufacturer` - this appears to be a schema issue (duplicate constraints).

---

## Self-Referential FKs

| Table | FK Column | Referenced Column | Notes |
|-------|-----------|-------------------|-------|
| recipe_part | part_recipe_id | recipe.id | Recipe can include other recipes |
| container_type_position | parent_container_type_id | container_type.id | Container hierarchy |
| container_type_position | child_container_type_id | container_type.id | Container hierarchy |

**PostgreSQL Consideration**: May need `DEFERRABLE INITIALLY DEFERRED` for bulk inserts.

---

## FK Data Type Summary

| Data Type | FK Count | Notes |
|-----------|----------|-------|
| INT -> INT | 120 | Standard integer FKs |
| NVARCHAR -> NVARCHAR | 4 | UID-based FKs (material lineage) |

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Created | 2026-01-26 |
| Total FK Constraints | 124 |
| CASCADE DELETE | 28 |
| SET NULL | 4 |
| NO ACTION | 92 |
| UID-based FKs | 4 |
