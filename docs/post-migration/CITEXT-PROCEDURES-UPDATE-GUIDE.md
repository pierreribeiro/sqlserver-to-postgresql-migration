# CITEXT Conversion -- Stored Procedures Update Guide

**User Story:** Deferred from US7 (Column Conversion to CITEXT)
**Audience:** Human development team AND future Claude agent worktree
**Status:** PENDING -- to be executed in a future User Story
**Created:** 2026-03-17

---

## Context

US7 converted **172 VARCHAR columns to CITEXT** across 65+ tables in the Perseus database. This enables case-insensitive comparisons natively at the column level, eliminating the need for `LOWER()`/`UPPER()` wrappers in queries and JOINs.

However, the **15 stored procedures** in `source/building/pgsql/refactored/20.create-procedure/` were NOT updated as part of US7. Their parameters, local variables, and explicit casts may still declare `VARCHAR` for columns that are now `CITEXT`. While PostgreSQL will perform implicit VARCHAR-to-CITEXT casting in many cases, the procedure signatures should be updated for:

1. **Type consistency** -- parameters should match the column types they reference
2. **Avoiding implicit cast overhead** -- explicit CITEXT parameters eliminate runtime casting
3. **Documentation accuracy** -- code should reflect the actual schema types
4. **Future maintainability** -- new developers should see CITEXT, not VARCHAR, for these columns

---

## Key CITEXT Columns Referenced by Procedures

These are the most frequently referenced columns that were converted from VARCHAR to CITEXT:

| Table | Column | Referenced By |
|---|---|---|
| `goo` | `uid` | addarc, removearc, getmaterialbyrunproperties, processdirtytrees, processsomemupstream, reconcilemupstream, updatemdownstream, updatemupstream |
| `goo` | `name` | linkunlinkedmaterials, getmaterialbyrunproperties |
| `goo` | `description` | (indirect references) |
| `goo` | `catalog_label` | (indirect references) |
| `fatsmurf` | `uid` | addarc, removearc, transitiontomaterial, materialtotransition |
| `material_transition` | `material_id` | addarc, removearc, transitiontomaterial, materialtotransition |
| `material_transition` | `transition_id` | addarc, removearc, transitiontomaterial, materialtotransition |
| `transition_material` | `material_id` | addarc, removearc, transitiontomaterial, materialtotransition |
| `transition_material` | `transition_id` | addarc, removearc, transitiontomaterial, materialtotransition |
| `m_upstream` | `start_point`, `end_point`, `path` | updatemupstream, reconcilemupstream, processsomemupstream |
| `m_downstream` | `start_point`, `end_point`, `path` | updatemdownstream |
| `m_upstream_dirty_leaves` | `material_uid` | processdirtytrees, reconcilemupstream |
| `container` | `uid`, `name`, `scope_id` | movecontainer, updatecontainertypefromargus |
| `container_type` | `name` | updatecontainertypefromargus |
| `goo_type` | `name`, `scope_id` | movegootype |

---

## Procedure-by-Procedure Analysis

### 1. `0.perseus.addarc.sql` -- AddArc

**File:** `source/building/pgsql/refactored/20.create-procedure/0.perseus.addarc.sql`

**Parameters requiring update:**
- `par_materialuid VARCHAR` --> `par_materialuid CITEXT` (references `goo.uid`)
- `par_transitionuid VARCHAR` --> `par_transitionuid CITEXT` (references `fatsmurf.uid`)
- `par_direction VARCHAR` --> review if this is a lookup value or enum (may stay VARCHAR)

**Local variables requiring update:**
- Any local variables storing `goo.uid` or `fatsmurf.uid` values

**Expected changes:**
- Update parameter types in CREATE OR REPLACE PROCEDURE signature
- Update DECLARE section variable types
- Review explicit `::VARCHAR` casts -- change to `::CITEXT` where referencing converted columns
- Verify string comparisons still work correctly (CITEXT is case-insensitive by default)

---

### 2. `1.perseus.getmaterialbyrunproperties.sql` -- GetMaterialByRunProperties

**File:** `source/building/pgsql/refactored/20.create-procedure/1.perseus.getmaterialbyrunproperties.sql`

**Parameters requiring update:**
- `par_runid VARCHAR` --> review if this references a CITEXT column (likely `goo.uid` pattern)

**Local variables requiring update:**
- `v_original_goo VARCHAR(50)` --> `v_original_goo CITEXT` (stores `goo.uid` values)
- `v_timepoint_goo VARCHAR(50)` --> `v_timepoint_goo CITEXT`
- `v_split VARCHAR(50)` --> `v_split CITEXT`

**Expected changes:**
- Update variable declarations
- Review any string manipulation functions (CITEXT behaves like TEXT for function calls)

---

### 3. `10.perseus.removearc.sql` -- RemoveArc

**File:** `source/building/pgsql/refactored/20.create-procedure/10.perseus.removearc.sql`

**Parameters requiring update:**
- `par_materialuid VARCHAR` --> `par_materialuid CITEXT`
- `par_transitionuid VARCHAR` --> `par_transitionuid CITEXT`
- `par_direction VARCHAR` --> review (may stay VARCHAR if it is an enum-like value)

**Local variables requiring update:**
- `v_target_table VARCHAR(50)` --> stays VARCHAR (this is a table name, not a CITEXT column value)

**Expected changes:**
- Mirror changes from AddArc (twin procedure)

---

### 4. `11.perseus.sp_move_node.sql` -- sp_move_node

**File:** `source/building/pgsql/refactored/20.create-procedure/11.perseus.sp_move_node.sql`

**Parameters requiring update:**
- Uses INTEGER parameters (par_childid, par_parentid) -- likely NO CITEXT changes needed

**Local variables requiring update:**
- Review any variables storing `scope_id` values (now CITEXT in `goo_type.scope_id`)

**Expected changes:**
- Minimal or none -- this procedure works with integer tree keys
- Audit any scope_id references

---

### 5. `12.perseus.transitiontomaterial.sql` -- TransitionToMaterial

**File:** `source/building/pgsql/refactored/20.create-procedure/12.perseus.transitiontomaterial.sql`

**Parameters requiring update:**
- `par_materialuid VARCHAR(50)` --> `par_materialuid CITEXT` (references `transition_material.material_id`)
- `par_transitionuid VARCHAR(50)` --> `par_transitionuid CITEXT` (references `transition_material.transition_id`)

**Expected changes:**
- Update parameter types
- The INSERT into `transition_material` will benefit from matching types

---

### 6. `3.perseus.materialtotransition.sql` -- MaterialToTransition

**File:** `source/building/pgsql/refactored/20.create-procedure/3.perseus.materialtotransition.sql`

**Parameters requiring update:**
- `par_materialuid VARCHAR(50)` --> `par_materialuid CITEXT` (references `material_transition.material_id`)
- `par_transitionuid VARCHAR(50)` --> `par_transitionuid CITEXT` (references `material_transition.transition_id`)

**Expected changes:**
- Twin of TransitionToMaterial -- apply same changes
- Update parameter types in signature

---

### 7. `4.perseus.movecontainer.sql` -- MoveContainer

**File:** `source/building/pgsql/refactored/20.create-procedure/4.perseus.movecontainer.sql`

**Parameters requiring update:**
- Uses INTEGER parameters -- NO parameter changes needed

**Local variables requiring update:**
- `var_myFormerScope VARCHAR(50)` --> `var_myFormerScope CITEXT` (stores `container.scope_id`)
- `var_TempScope VARCHAR(50)` --> `var_TempScope CITEXT` (stores generated scope_id)
- `var_myParentScope VARCHAR(50)` --> `var_myParentScope CITEXT`

**Expected changes:**
- Update variable declarations for scope_id handling
- Review gen_random_uuid() cast -- UUID to CITEXT instead of UUID to VARCHAR

---

### 8. `5.perseus.movegootype.sql` -- MoveGooType

**File:** `source/building/pgsql/refactored/20.create-procedure/5.perseus.movegootype.sql`

**Parameters requiring update:**
- Uses INTEGER parameters -- NO parameter changes needed

**Local variables requiring update:**
- `var_myFormerScope VARCHAR(50)` --> `var_myFormerScope CITEXT` (stores `goo_type.scope_id`)
- `var_TempScope VARCHAR(50)` --> `var_TempScope CITEXT`
- `var_myParentScope VARCHAR(50)` --> `var_myParentScope CITEXT`

**Expected changes:**
- Twin of MoveContainer -- apply same variable type changes

---

### 9. `6.perseus.processdirtytrees.sql` -- ProcessDirtyTrees

**File:** `source/building/pgsql/refactored/20.create-procedure/6.perseus.processdirtytrees.sql`

**Parameters requiring update:**
- `par_dirty_in perseus_dbo.goolist` --> review GooList type definition (uid column should be CITEXT)
- `par_clean_in perseus_dbo.goolist` --> same

**Local variables requiring update:**
- `v_current_uid VARCHAR(50)` --> `v_current_uid CITEXT` (stores `goo.uid` values)
- `v_processed_uid VARCHAR(50)` --> `v_processed_uid CITEXT`

**Expected changes:**
- Update variable types
- Verify GooList type definition has been updated (uid column = CITEXT)

---

### 10. `7.perseus.processsomemupstream.sql` -- ProcessSomeMUpstream

**File:** `source/building/pgsql/refactored/20.create-procedure/7.perseus.processsomemupstream.sql`

**Parameters requiring update:**
- GooList-typed parameters -- same note as ProcessDirtyTrees

**Local variables requiring update:**
- Any variables storing `goo.uid` or `m_upstream` path values

**Expected changes:**
- Update uid-related variable types to CITEXT
- Review path-related variables (m_upstream.path is now CITEXT)

---

### 11. `9.perseus.reconcilemupstream.sql` -- ReconcileMUpstream

**File:** `source/building/pgsql/refactored/20.create-procedure/9.perseus.reconcilemupstream.sql`

**Parameters requiring update:**
- GooList-typed parameters -- dependent on GooList type update

**Local variables requiring update:**
- Variables storing `goo.uid`, `m_upstream.start_point`, `m_upstream.end_point`, `m_upstream.path`

**Expected changes:**
- Update variable types for uid and path storage
- Review DELETE/INSERT operations on m_upstream -- types should match

---

### 12. `2.perseus.linkunlinkedmaterials.sql` -- LinkUnlinkedMaterials

**File:** `source/building/pgsql/refactored/20.create-procedure/2.perseus.linkunlinkedmaterials.sql`

**Parameters requiring update:**
- No input parameters (parameterless procedure)

**Local variables requiring update:**
- Review variables that store `goo.uid`, `goo.name`, `material_transition.material_id`, `transition_material.material_id` values

**Expected changes:**
- Update relevant variable declarations
- Review any temporary table definitions within the procedure

---

### 13. `13.perseus.usp_updatecontainertypefromargus.sql` -- usp_UpdateContainerTypeFromArgus

**File:** `source/building/pgsql/refactored/20.create-procedure/13.perseus.usp_updatecontainertypefromargus.sql`

**Parameters requiring update:**
- No input parameters (parameterless procedure)

**Local variables requiring update:**
- Variables storing `container.uid` (now CITEXT)
- Variables storing `container_type.name` (now CITEXT)

**Expected changes:**
- Update variable types
- Review FDW (foreign data wrapper) queries -- Argus remote table types will NOT change, so explicit casts may be needed at the FDW boundary

**Special note:** This procedure queries a remote Argus database via postgres_fdw. The remote columns remain their original types. Explicit `::CITEXT` casts should be applied when assigning foreign table values to local CITEXT variables.

---

### 14. `14.perseus.usp_updatemdownstream.sql` -- usp_UpdateMDownstream

**File:** `source/building/pgsql/refactored/20.create-procedure/14.perseus.usp_updatemdownstream.sql`

**Parameters requiring update:**
- No input parameters (parameterless procedure)

**Local variables requiring update:**
- Variables storing `goo.uid` values
- Variables storing `m_downstream.start_point`, `m_downstream.end_point`, `m_downstream.path` values

**Expected changes:**
- Update variable types for uid and path storage
- Review temporary table definitions (uid column should be CITEXT)
- Review INSERT INTO m_downstream -- column types should match

---

### 15. `15.perseus.usp_updatemupstream.sql` -- usp_UpdateMUpstream

**File:** `source/building/pgsql/refactored/20.create-procedure/15.perseus.usp_updatemupstream.sql`

**Parameters requiring update:**
- No input parameters (parameterless procedure)

**Local variables requiring update:**
- Variables storing `goo.uid` values
- Variables storing `m_upstream.start_point`, `m_upstream.end_point`, `m_upstream.path` values

**Expected changes:**
- Update variable types for uid and path storage
- Mirror changes from usp_UpdateMDownstream (twin procedure)

---

## Testing Checklist

For EACH procedure after updating:

- [ ] **Syntax validation:** `psql -d perseus_dev -f <procedure>.sql` deploys without errors
- [ ] **Existing unit tests pass:** `psql -d perseus_dev -f tests/unit/test_<procedure>.sql`
- [ ] **Parameter type verification:** Query `pg_catalog.pg_proc` to confirm parameter types are CITEXT
- [ ] **Implicit cast elimination:** No `WARNING: implicit cast` messages in PostgreSQL logs during test execution
- [ ] **Case-insensitive behavior:** Test with mixed-case input values (e.g., `'M12345'` vs `'m12345'`) and verify identical results
- [ ] **FDW boundary casts (procedure 13 only):** Verify explicit casts at foreign table boundary
- [ ] **Performance regression:** Run EXPLAIN ANALYZE on key queries within each procedure -- results should be within +/-20% of pre-update baseline
- [ ] **Integration test:** Call procedures in sequence matching production workflow (AddArc --> McGetUpStream --> ReconcileMUpstream chain)

### Priority Order for Testing

1. **P0 Critical chain:** AddArc, RemoveArc (call McGet* functions)
2. **P0 Reconciliation:** ReconcileMUpstream, ProcessSomeMUpstream, ProcessDirtyTrees
3. **P1 Graph maintenance:** usp_UpdateMUpstream, usp_UpdateMDownstream
4. **P1 Arc operations:** TransitionToMaterial, MaterialToTransition
5. **P2 Remaining:** GetMaterialByRunProperties, LinkUnlinkedMaterials, MoveContainer, MoveGooType, sp_move_node, usp_UpdateContainerTypeFromArgus

---

## Reference Files

- **CITEXT candidate columns:** `prompts/columns_citext_candidates.txt` (172 ALTER statements)
- **Dependency analysis:** `docs/post-migration/citext-dependency-analysis.md`
- **Procedure source files:** `source/building/pgsql/refactored/20.create-procedure/`
- **Existing unit tests:** `tests/unit/`
- **Data dictionary:** `docs/db-design/pgsql/perseus-data-dictionary.md`
- **Type reference:** `docs/db-design/pgsql/TYPE-TRANSFORMATION-REFERENCE.md`
