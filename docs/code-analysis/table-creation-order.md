# Table Creation Order - Perseus Database Migration

## Executive Summary

**Total Tables:** 101
**Schemas:** 3 (dbo, hermes, demeter)
**Creation Tiers:** 5 (0-4)
**Circular Dependencies:** NONE

This document provides the dependency-safe creation order for all 101 tables in the Perseus database.

---

## Dependency-Safe Creation Sequence

### Phase 0: Schema Creation

```sql
-- Create schemas first (if not exists)
0. CREATE SCHEMA IF NOT EXISTS dbo;
1. CREATE SCHEMA IF NOT EXISTS hermes;
2. CREATE SCHEMA IF NOT EXISTS demeter;
```

---

### Phase 1: Tier 0 - Base Tables (38 tables)

**No dependencies - can be created in parallel**

#### DBO Schema Tier 0 (32 tables)

```
0.  dbo.alembic_version
1.  dbo.cm_application
2.  dbo.cm_application_group
3.  dbo.cm_group
4.  dbo.cm_project
5.  dbo.cm_unit
6.  dbo.cm_unit_compare
7.  dbo.cm_unit_dimensions
8.  dbo.cm_user
9.  dbo.cm_user_group
10. dbo.color
11. dbo.container_type
12. dbo.display_layout
13. dbo.display_type
14. dbo.field_map_block
15. dbo.field_map_set
16. dbo.field_map_type
17. dbo.goo_attachment_type
18. dbo.goo_process_queue_type
19. dbo.goo_type                    ** P0 CRITICAL **
20. dbo.history_type
21. dbo.m_downstream                ** P0 CRITICAL **
22. dbo.m_number
23. dbo.m_upstream                  ** P0 CRITICAL **
24. dbo.m_upstream_dirty_leaves
25. dbo.manufacturer
26. dbo.migration
27. dbo.Permissions
28. dbo.PerseusTableAndRowCounts
29. dbo.person
30. dbo.prefix_incrementor
31. dbo.s_number
32. dbo.Scraper
33. dbo.sequence_type
34. dbo.smurf
35. dbo.tmp_messy_links
36. dbo.unit
37. dbo.workflow_step_type
```

#### Hermes Schema Tier 0 (6 tables)

```
38. hermes.run
39. hermes.run_condition
40. hermes.run_condition_option
41. hermes.run_condition_value
42. hermes.run_master_condition
43. hermes.run_master_condition_type
```

#### Demeter Schema Tier 0 (2 tables)

```
44. demeter.barcodes
45. demeter.seed_vials
```

---

### Phase 2: Tier 1 - First Level Dependencies (10 tables)

**Dependencies: Tier 0 tables only**

```
46. dbo.coa                         -> goo_type
47. dbo.container                   -> container_type
48. dbo.container_type_position     -> container_type (x2)
49. dbo.external_goo_type           -> goo_type, manufacturer
50. dbo.goo_type_combine_target     -> goo_type
51. dbo.history                     -> perseus_user, history_type  [REQUIRES #55]
52. dbo.property                    -> unit
53. dbo.robot_log_type              -> container_type
54. dbo.workflow                    -> perseus_user, manufacturer  [REQUIRES #55]
55. dbo.perseus_user                -> manufacturer  ** P0 CRITICAL **
```

**IMPORTANT**: `perseus_user` must be created BEFORE `history` and `workflow` due to FK dependencies.

**Recommended Order:**
```
46. dbo.coa
47. dbo.container
48. dbo.container_type_position
49. dbo.external_goo_type
50. dbo.goo_type_combine_target
51. dbo.property
52. dbo.robot_log_type
53. dbo.perseus_user                ** CREATE FIRST **
54. dbo.history                     (after perseus_user)
55. dbo.workflow                    (after perseus_user)
```

---

### Phase 3: Tier 2 - Second Level Dependencies (14 tables)

**Dependencies: Tier 0 and Tier 1 tables**

```
56. dbo.coa_spec                    -> coa, property
57. dbo.container_history           -> history, container
58. dbo.feed_type                   -> perseus_user (x2)
59. dbo.field_map                   -> field_map_block, field_map_type, field_map_set
60. dbo.goo_type_combine_component  -> goo_type, goo_type_combine_target
61. dbo.history_value               -> history
62. dbo.property_option             -> property
63. dbo.robot_run                   -> container
64. dbo.saved_search                -> perseus_user
65. dbo.smurf_goo_type              -> smurf, goo_type
66. dbo.smurf_group                 -> perseus_user
67. dbo.smurf_property              -> property, smurf
68. dbo.workflow_attachment         -> perseus_user, workflow
69. dbo.workflow_step               -> goo_type, property, smurf, workflow, unit
```

---

### Phase 4: Tier 3 - Third Level Dependencies (17 tables)

**Dependencies: Tiers 0, 1, and 2**

**Sub-phase 4a - Create recipe first (required by goo):**
```
70. dbo.recipe                      -> perseus_user, feed_type, goo_type, workflow
```

**Sub-phase 4b - Create recipe_part (required by goo):**
```
71. dbo.recipe_part                 -> goo_type, recipe (x2), unit, workflow_step
```

**Sub-phase 4c - Create fatsmurf (required by goo and material_transition):**
```
72. dbo.fatsmurf                    -> smurf, container, manufacturer, workflow_step
                                    ** P0 CRITICAL **
```

**Sub-phase 4d - Create goo:**
```
73. dbo.goo                         -> goo_type, perseus_user, manufacturer,
                                       container, workflow_step, recipe, recipe_part
                                    ** P0 CRITICAL **
```

**Sub-phase 4e - Remaining Tier 3 tables:**
```
74. dbo.fatsmurf_reading            -> perseus_user, fatsmurf
75. dbo.field_map_display_type      -> field_map, display_type, display_layout
76. dbo.field_map_display_type_user -> perseus_user
77. dbo.poll                        -> fatsmurf_reading, smurf_property
78. dbo.recipe_project_assignment   -> recipe
79. dbo.robot_log                   -> robot_log_type, robot_run
80. dbo.smurf_group_member          -> smurf, smurf_group
81. dbo.submission                  -> perseus_user
82. dbo.workflow_section            -> workflow, workflow_step
```

---

### Phase 5: Tier 4 - Fourth Level Dependencies (21 tables)

**Dependencies: All previous tiers**

**Sub-phase 5a - Direct goo/fatsmurf children:**
```
83. dbo.fatsmurf_attachment         -> perseus_user, fatsmurf
84. dbo.fatsmurf_comment            -> perseus_user, fatsmurf
85. dbo.fatsmurf_history            -> history, fatsmurf
86. dbo.goo_attachment              -> perseus_user, goo, goo_attachment_type
87. dbo.goo_comment                 -> perseus_user, goo
88. dbo.goo_history                 -> history, goo
```

**Sub-phase 5b - Material tracking tables:**
```
89. dbo.material_inventory          -> container (x2), perseus_user (x2), goo, recipe
90. dbo.material_inventory_threshold -> perseus_user (x2), goo_type
91. dbo.material_qc                 -> goo
```

**Sub-phase 5c - P0 CRITICAL - Material Lineage Tables:**
```
92. dbo.material_transition         -> fatsmurf (uid), goo (uid)
                                    ** P0 CRITICAL - Parent->Transition edges **
93. dbo.transition_material         -> fatsmurf (uid), goo (uid)
                                    ** P0 CRITICAL - Transition->Child edges **
```

**Sub-phase 5d - Robot and submission tables:**
```
94. dbo.poll_history                -> history, poll
95. dbo.robot_log_container_sequence -> sequence_type, container, robot_log
96. dbo.robot_log_error             -> robot_log
97. dbo.robot_log_read              -> goo, robot_log, property
98. dbo.robot_log_transfer          -> goo (x2), robot_log
99. dbo.submission_entry            -> smurf, goo, perseus_user, submission
```

**Sub-phase 5e - Notification table:**
```
100. dbo.material_inventory_threshold_notify_user -> material_inventory_threshold, perseus_user
```

---

## Complete Ordered List (0-100)

```
# Phase 0: Schemas
CREATE SCHEMA dbo;
CREATE SCHEMA hermes;
CREATE SCHEMA demeter;

# Phase 1: Tier 0 - Base Tables (0-45)
0.   dbo.alembic_version
1.   dbo.cm_application
2.   dbo.cm_application_group
3.   dbo.cm_group
4.   dbo.cm_project
5.   dbo.cm_unit
6.   dbo.cm_unit_compare
7.   dbo.cm_unit_dimensions
8.   dbo.cm_user
9.   dbo.cm_user_group
10.  dbo.color
11.  dbo.container_type
12.  dbo.display_layout
13.  dbo.display_type
14.  dbo.field_map_block
15.  dbo.field_map_set
16.  dbo.field_map_type
17.  dbo.goo_attachment_type
18.  dbo.goo_process_queue_type
19.  dbo.goo_type                       [P0 CRITICAL]
20.  dbo.history_type
21.  dbo.m_downstream                   [P0 CRITICAL]
22.  dbo.m_number
23.  dbo.m_upstream                     [P0 CRITICAL]
24.  dbo.m_upstream_dirty_leaves
25.  dbo.manufacturer
26.  dbo.migration
27.  dbo.Permissions
28.  dbo.PerseusTableAndRowCounts
29.  dbo.person
30.  dbo.prefix_incrementor
31.  dbo.s_number
32.  dbo.Scraper
33.  dbo.sequence_type
34.  dbo.smurf
35.  dbo.tmp_messy_links
36.  dbo.unit
37.  dbo.workflow_step_type
38.  hermes.run
39.  hermes.run_condition
40.  hermes.run_condition_option
41.  hermes.run_condition_value
42.  hermes.run_master_condition
43.  hermes.run_master_condition_type
44.  demeter.barcodes
45.  demeter.seed_vials

# Phase 2: Tier 1 (46-55)
46.  dbo.coa
47.  dbo.container
48.  dbo.container_type_position
49.  dbo.external_goo_type
50.  dbo.goo_type_combine_target
51.  dbo.property
52.  dbo.robot_log_type
53.  dbo.perseus_user                   [P0 CRITICAL]
54.  dbo.history
55.  dbo.workflow

# Phase 3: Tier 2 (56-69)
56.  dbo.coa_spec
57.  dbo.container_history
58.  dbo.feed_type
59.  dbo.field_map
60.  dbo.goo_type_combine_component
61.  dbo.history_value
62.  dbo.property_option
63.  dbo.robot_run
64.  dbo.saved_search
65.  dbo.smurf_goo_type
66.  dbo.smurf_group
67.  dbo.smurf_property
68.  dbo.workflow_attachment
69.  dbo.workflow_step

# Phase 4: Tier 3 (70-82)
70.  dbo.recipe
71.  dbo.recipe_part
72.  dbo.fatsmurf                       [P0 CRITICAL]
73.  dbo.goo                            [P0 CRITICAL]
74.  dbo.fatsmurf_reading
75.  dbo.field_map_display_type
76.  dbo.field_map_display_type_user
77.  dbo.poll
78.  dbo.recipe_project_assignment
79.  dbo.robot_log
80.  dbo.smurf_group_member
81.  dbo.submission
82.  dbo.workflow_section

# Phase 5: Tier 4 (83-100)
83.  dbo.fatsmurf_attachment
84.  dbo.fatsmurf_comment
85.  dbo.fatsmurf_history
86.  dbo.goo_attachment
87.  dbo.goo_comment
88.  dbo.goo_history
89.  dbo.material_inventory
90.  dbo.material_inventory_threshold
91.  dbo.material_qc
92.  dbo.material_transition            [P0 CRITICAL]
93.  dbo.transition_material            [P0 CRITICAL]
94.  dbo.poll_history
95.  dbo.robot_log_container_sequence
96.  dbo.robot_log_error
97.  dbo.robot_log_read
98.  dbo.robot_log_transfer
99.  dbo.submission_entry
100. dbo.material_inventory_threshold_notify_user
```

---

## P0 Critical Tables Summary

| Order | Table | Tier | Purpose |
|-------|-------|------|---------|
| 19 | goo_type | 0 | Material type definitions |
| 21 | m_downstream | 0 | Cached downstream lineage graph |
| 23 | m_upstream | 0 | Cached upstream lineage graph |
| 53 | perseus_user | 1 | User accounts (referenced by most tables) |
| 72 | fatsmurf | 3 | Experiments/transitions |
| 73 | goo | 3 | Materials (core entity) |
| 92 | material_transition | 4 | Parent-to-transition edges |
| 93 | transition_material | 4 | Transition-to-child edges |

---

## Validation Checkpoints

### After Phase 1 (Tier 0):
- [ ] All 46 base tables created successfully
- [ ] No FK constraints to validate yet
- [ ] `goo_type`, `m_upstream`, `m_downstream` must exist

### After Phase 2 (Tier 1):
- [ ] `perseus_user` exists (required by most Tier 2+ tables)
- [ ] `container`, `workflow`, `history` created
- [ ] FK constraints to Tier 0 tables validate successfully

### After Phase 3 (Tier 2):
- [ ] `workflow_step` exists (required by fatsmurf, goo)
- [ ] `property`, `smurf_property` exist

### After Phase 4 (Tier 3):
- [ ] `recipe`, `recipe_part` exist (required by goo)
- [ ] `fatsmurf` exists with `uid` column indexed
- [ ] `goo` exists with `uid` column indexed

### After Phase 5 (Tier 4):
- [ ] `material_transition` created with FKs to goo.uid and fatsmurf.uid
- [ ] `transition_material` created with FKs to goo.uid and fatsmurf.uid
- [ ] All 124 FK constraints validate successfully

---

## PostgreSQL Migration Notes

### Index Requirements Before FK Creation:

```sql
-- Required before creating material_transition and transition_material FKs
CREATE UNIQUE INDEX idx_goo_uid ON dbo.goo(uid);
CREATE UNIQUE INDEX idx_fatsmurf_uid ON dbo.fatsmurf(uid);
```

### Deferred Constraints for Self-Referential Tables:

```sql
-- For recipe_part.part_recipe_id -> recipe.id
ALTER TABLE dbo.recipe_part
  ALTER CONSTRAINT fk_recipe_part_part_recipe_id DEFERRABLE INITIALLY DEFERRED;
```

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Created | 2026-01-26 |
| Total Tables | 101 |
| Creation Phases | 6 (0-5) |
| P0 Critical Tables | 8 |
