# Table Dependency Graph - Perseus Database Migration

## Executive Summary

**Analysis Date:** 2026-01-26
**Analyst:** Claude (Database Architect Agent) + Pierre Ribeiro
**Scope:** 101 tables across 3 schemas (dbo, hermes, demeter)
**Foreign Key Constraints:** 124 FK relationships analyzed

---

## Schema Distribution

| Schema | Table Count | FK Constraints | Notes |
|--------|-------------|----------------|-------|
| **dbo** | 91 | 122 | Core Perseus tables |
| **hermes** | 6 | 0 | Experiment/fermentation data |
| **demeter** | 2 | 0 | Seed vial tracking |
| **TOTAL** | **101** | **124** | 2 additional auxiliary tables (Permissions, PerseusTableAndRowCounts) |

---

## Tier Classification

Tables are classified into dependency tiers based on foreign key relationships:
- **Tier 0 (Base)**: No FK dependencies - can be created first
- **Tier 1**: Depends only on Tier 0 tables
- **Tier 2**: Depends on Tier 0 and/or Tier 1 tables
- **Tier 3+**: Higher-level dependencies

---

## Tier 0 - Base Tables (No FK Dependencies) - 38 Tables

These tables have NO foreign key constraints pointing to other tables and can be created first.

### DBO Schema (32 tables)

| # | Table Name | Columns | Notes |
|---|------------|---------|-------|
| 1 | alembic_version | 1 | Migration tracking |
| 2 | cm_application | 5 | Application config |
| 3 | cm_application_group | 3 | Application groups |
| 4 | cm_group | 4 | User groups |
| 5 | cm_project | 4 | Project definitions |
| 6 | cm_unit | 5 | Unit config |
| 7 | cm_unit_compare | 2 | Unit comparisons |
| 8 | cm_unit_dimensions | 6 | Unit dimensions |
| 9 | cm_user | 5 | User config |
| 10 | cm_user_group | 2 | User-group mapping |
| 11 | color | 2 | Color definitions |
| 12 | container_type | 5 | Container types |
| 13 | display_layout | 2 | Display layouts |
| 14 | display_type | 2 | Display types |
| 15 | field_map_block | 3 | Field map blocks |
| 16 | field_map_set | 4 | Field map sets |
| 17 | field_map_type | 2 | Field map types |
| 18 | goo_attachment_type | 2 | Attachment types |
| 19 | goo_process_queue_type | 2 | Queue types |
| 20 | **goo_type** | 8 | **P0 CRITICAL - Material types** |
| 21 | history_type | 3 | History types |
| 22 | **m_downstream** | 4 | **P0 CRITICAL - Cached downstream graph** |
| 23 | m_number | 1 | M-number sequence |
| 24 | **m_upstream** | 4 | **P0 CRITICAL - Cached upstream graph** |
| 25 | m_upstream_dirty_leaves | 2 | Dirty tracking |
| 26 | manufacturer | 4 | Manufacturers |
| 27 | migration | 3 | Migration tracking |
| 28 | Permissions | 3 | Permission definitions |
| 29 | PerseusTableAndRowCounts | 4 | Row count tracking |
| 30 | prefix_incrementor | 2 | Prefix sequences |
| 31 | s_number | 1 | S-number sequence |
| 32 | Scraper | 8 | Scraper config |
| 33 | sequence_type | 2 | Sequence types |
| 34 | smurf | 4 | Smurf definitions |
| 35 | tmp_messy_links | 5 | Temporary cleanup |
| 36 | unit | 4 | Units of measure |
| 37 | workflow_step_type | 2 | Workflow step types |
| 38 | person | 6 | Person records |

### Hermes Schema (6 tables - No FKs)

| # | Table Name | Columns | Notes |
|---|------------|---------|-------|
| 1 | run | 94 | Fermentation runs |
| 2 | run_condition | 3 | Run conditions |
| 3 | run_condition_option | 3 | Condition options |
| 4 | run_condition_value | 3 | Condition values |
| 5 | run_master_condition | 6 | Master conditions |
| 6 | run_master_condition_type | 2 | Condition types |

### Demeter Schema (2 tables - No FKs)

| # | Table Name | Columns | Notes |
|---|------------|---------|-------|
| 1 | barcodes | 3 | Barcode tracking |
| 2 | seed_vials | 26 | Seed vial inventory |

---

## Tier 1 - First Level Dependencies (22 Tables)

These tables have FK constraints ONLY to Tier 0 tables.

| # | Table Name | Dependencies (Parent Tables) | On Delete | Notes |
|---|------------|------------------------------|-----------|-------|
| 1 | coa | goo_type | - | Certificate of Analysis |
| 2 | container | container_type | - | Container instances |
| 3 | container_type_position | container_type (x2) | - | Parent/child positions |
| 4 | external_goo_type | goo_type, manufacturer | - | External type mapping |
| 5 | goo_type_combine_target | goo_type | - | Combine targets |
| 6 | history | perseus_user, history_type | - | History records |
| 7 | **perseus_user** | manufacturer (x3) | - | **P0 CRITICAL - Users** |
| 8 | property | unit | - | Property definitions |
| 9 | robot_log_type | container_type | - | Robot log types |
| 10 | workflow | perseus_user, manufacturer | - | Workflow definitions |

---

## Tier 2 - Second Level Dependencies (28 Tables)

These tables depend on Tier 0 and Tier 1 tables.

| # | Table Name | Dependencies | On Delete | Notes |
|---|------------|--------------|-----------|-------|
| 1 | coa_spec | coa, property | - | COA specifications |
| 2 | container_history | history, container | CASCADE | Container history |
| 3 | feed_type | perseus_user (x2) | - | Feed types |
| 4 | field_map | field_map_block, field_map_type, field_map_set | - | Field mapping |
| 5 | goo_type_combine_component | goo_type, goo_type_combine_target | CASCADE | Combine components |
| 6 | history_value | history | CASCADE | History values |
| 7 | property_option | property | - | Property options |
| 8 | robot_run | container | - | Robot runs |
| 9 | saved_search | perseus_user | - | Saved searches |
| 10 | smurf_goo_type | smurf, goo_type | CASCADE | Smurf-goo mapping |
| 11 | smurf_group | perseus_user | - | Smurf groups |
| 12 | smurf_property | property, smurf | CASCADE | Smurf properties |
| 13 | workflow_attachment | perseus_user, workflow | CASCADE | Workflow attachments |
| 14 | workflow_step | goo_type, property, smurf, workflow, unit | CASCADE | Workflow steps |

---

## Tier 3 - Third Level Dependencies (17 Tables)

These tables have deeper dependency chains.

| # | Table Name | Dependencies | Key Parent | Notes |
|---|------------|--------------|------------|-------|
| 1 | **fatsmurf** | smurf, container, manufacturer, workflow_step | workflow_step | **P0 - Experiments** |
| 2 | field_map_display_type | field_map, display_type, display_layout | field_map | Field display |
| 3 | field_map_display_type_user | perseus_user | perseus_user | User display prefs |
| 4 | **goo** | goo_type, perseus_user, manufacturer, container, workflow_step, recipe, recipe_part | **CRITICAL** | **P0 - Materials** |
| 5 | poll | fatsmurf_reading, smurf_property | smurf_property | Poll data |
| 6 | recipe | perseus_user, feed_type, goo_type, workflow | workflow | Recipes |
| 7 | robot_log | robot_log_type, robot_run | robot_run | Robot logs |
| 8 | smurf_group_member | smurf, smurf_group | smurf_group | Group membership |
| 9 | submission | perseus_user | perseus_user | Submissions |
| 10 | workflow_section | workflow, workflow_step | workflow | Workflow sections |

---

## Tier 4 - Fourth Level Dependencies (13 Tables)

These tables have the deepest dependency chains.

| # | Table Name | Dependencies | Key Parent | On Delete | Notes |
|---|------------|--------------|------------|-----------|-------|
| 1 | fatsmurf_attachment | perseus_user, fatsmurf | fatsmurf | CASCADE | |
| 2 | fatsmurf_comment | perseus_user, fatsmurf | fatsmurf | CASCADE | |
| 3 | fatsmurf_history | history, fatsmurf | fatsmurf | CASCADE | |
| 4 | fatsmurf_reading | perseus_user, fatsmurf | fatsmurf | CASCADE | |
| 5 | goo_attachment | perseus_user, goo, goo_attachment_type | goo | CASCADE | |
| 6 | goo_comment | perseus_user, goo | goo | CASCADE | |
| 7 | goo_history | history, goo | goo | CASCADE | |
| 8 | material_inventory | container (x2), perseus_user (x2), goo, recipe | goo | - | |
| 9 | material_inventory_threshold | perseus_user (x2), goo_type | goo_type | - | |
| 10 | material_qc | goo | goo | - | |
| 11 | **material_transition** | **fatsmurf (uid), goo (uid)** | **goo, fatsmurf** | **CASCADE** | **P0 CRITICAL** |
| 12 | poll_history | history, poll | poll | CASCADE | |
| 13 | recipe_part | goo_type, recipe (x2), unit, workflow_step | recipe | - | |
| 14 | recipe_project_assignment | recipe | recipe | - | |
| 15 | robot_log_container_sequence | sequence_type, container, robot_log | robot_log | CASCADE | |
| 16 | robot_log_error | robot_log | robot_log | CASCADE | |
| 17 | robot_log_read | goo, robot_log, property | robot_log | CASCADE | |
| 18 | robot_log_transfer | goo (x2), robot_log | robot_log | CASCADE | |
| 19 | submission_entry | smurf, goo, perseus_user, submission | submission | - | |
| 20 | **transition_material** | **fatsmurf (uid), goo (uid)** | **goo, fatsmurf** | **CASCADE** | **P0 CRITICAL** |
| 21 | material_inventory_threshold_notify_user | material_inventory_threshold, perseus_user | material_inventory_threshold | CASCADE | |

---

## P0 Critical Path Tables

These tables form the core material lineage tracking system:

```
                         +------------------+
                         |    goo_type      |  (Tier 0)
                         +--------+---------+
                                  |
                                  v
+------------------+    +------------------+    +------------------+
|   m_upstream     |    |      goo         |    |   m_downstream   |
|   (Tier 0)       |<---|    (Tier 3)      |--->|     (Tier 0)     |
+------------------+    +--------+---------+    +------------------+
                                  |
                    +-------------+-------------+
                    |                           |
                    v                           v
          +------------------+        +------------------+
          |material_transition|        |transition_material|
          |    (Tier 4)       |        |     (Tier 4)      |
          +--------+---------+        +--------+---------+
                    |                           |
                    v                           v
          +------------------+        +------------------+
          |    fatsmurf      |        |    fatsmurf      |
          |   (Tier 3)       |        |    (Tier 3)      |
          +------------------+        +------------------+
```

### Critical Dependencies for `translated` View:

```sql
-- The translated view joins these two tables:
-- material_transition.material_id -> goo.uid
-- material_transition.transition_id -> fatsmurf.uid
-- transition_material.transition_id -> fatsmurf.uid
-- transition_material.material_id -> goo.uid
```

---

## Circular Dependencies Analysis

**RESULT: NO CIRCULAR DEPENDENCIES DETECTED**

All foreign key relationships form a directed acyclic graph (DAG). The tables can be created in the specified tier order without circular reference issues.

### Potential Cross-Reference (Not Circular):
- `workflow_section.starting_step_id` -> `workflow_step.id`
- `workflow_step.scope_id` -> `workflow.id`
- `workflow_section.workflow_id` -> `workflow.id`

This is NOT circular because:
1. `workflow` is created first (Tier 1)
2. `workflow_step` is created second (Tier 2)
3. `workflow_section` is created last (Tier 2, after workflow_step)

The FK `workflow_section.starting_step_id` is a forward reference that requires `workflow_step` to exist first.

---

## Self-Referential Tables

The following tables have self-referential FKs (parent-child within same table):

| Table | FK Column | Notes |
|-------|-----------|-------|
| recipe_part | part_recipe_id -> recipe.id | Recipe can reference other recipes |
| container_type_position | parent_container_type_id, child_container_type_id -> container_type.id | Container hierarchy |

**Impact**: These require careful INSERT order or deferred constraint checking.

---

## Tables with CASCADE DELETE

The following tables have `ON DELETE CASCADE` behavior that will propagate deletes:

| Parent Table | Child Table | Constraint Name |
|--------------|-------------|-----------------|
| fatsmurf | fatsmurf_attachment | fatsmurf_attachment_FK_2 |
| fatsmurf | fatsmurf_comment | fatsmurf_comment_FK_2 |
| fatsmurf | fatsmurf_history | fatsmurf_history_FK_2 |
| fatsmurf | fatsmurf_reading | fatsmurf_reading_FK_1 |
| **fatsmurf (uid)** | **material_transition** | FK_material_transition_fatsmurf |
| **fatsmurf (uid)** | **transition_material** | FK_transition_material_fatsmurf |
| goo | goo_attachment | goo_attachment_FK_2 |
| goo | goo_comment | goo_comment_FK_2 |
| goo | goo_history | goo_history_FK_2 |
| **goo (uid)** | **material_transition** | FK_material_transition_goo |
| **goo (uid)** | **transition_material** | FK_transition_material_goo |
| history | container_history | container_history_FK_1 |
| history | fatsmurf_history | fatsmurf_history_FK_1 |
| history | goo_history | goo_history_FK_1 |
| history | history_value | history_value_FK_1 |
| history | poll_history | poll_history_FK_1 |
| workflow | workflow_attachment | workflow_attachment_FK_2 |
| workflow | workflow_section | workflow_section_FK_1 |
| workflow | workflow_step | FK_workflow_step_workflow |

**CRITICAL NOTE**: Deleting a `goo` or `fatsmurf` record will CASCADE to `material_transition` and `transition_material`, affecting the material lineage graph.

---

## Tables with SET NULL on DELETE

| Parent Table | Child Table | Column |
|--------------|-------------|--------|
| container | fatsmurf | container_id |
| container | goo | container_id |
| workflow_step | fatsmurf | workflow_step_id |
| workflow_step | goo | workflow_step_id |

---

## Special FK Reference Types

### UID-Based Foreign Keys (Non-Integer)

| Table | FK Column | Referenced Table | Referenced Column |
|-------|-----------|------------------|-------------------|
| material_transition | material_id (nvarchar) | goo | uid |
| material_transition | transition_id (nvarchar) | fatsmurf | uid |
| transition_material | material_id (nvarchar) | goo | uid |
| transition_material | transition_id (nvarchar) | fatsmurf | uid |

**PostgreSQL Migration Note**: These use `nvarchar(50)` as FK columns referencing `uid` columns, not integer IDs. Ensure proper indexing on `goo.uid` and `fatsmurf.uid` columns.

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Created | 2026-01-26 |
| Tables Analyzed | 101 |
| FK Constraints | 124 |
| Circular Dependencies | 0 (NONE) |
| Blocking Issues | 0 (NONE) |
