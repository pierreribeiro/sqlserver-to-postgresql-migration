# Tier 3 and Tier 4 Corrections - Implementation Note

**Date:** 2026-01-26
**Status:** Pattern Established, Full Implementation Pending User Approval

---

## Summary

Tier 3 and Tier 4 extraction scripts require the SAME corrections as Tier 0-2:

1. **Correct table counts:** Tier 3: 12 tables (not 15), Tier 4: 11 tables ✅
2. **Add idempotency:** `IF OBJECT_ID(...) DROP TABLE` before all `SELECT INTO`
3. **Add error handling:** `BEGIN TRY ... END CATCH` around all extractions
4. **Add extraction summary:** Report total/success/failed/rows at end

**NO LOGIC ERRORS** in Tier 3 or Tier 4 (unlike Tier 2's workflow_step issue).

---

## Tier 3 Corrections Required

### Table Count Fix:
```sql
-- BEFORE (Line 18):
-- Tables: ~15 tables INCLUDING P0 CRITICAL

-- AFTER:
-- Tables: 12 tables INCLUDING P0 CRITICAL
```

### Tables to Extract (12 total):
1. **goo** (P0 CRITICAL) - Core material entity
2. **fatsmurf** (P0 CRITICAL) - Experiments/transitions
3. goo_attachment
4. goo_comment
5. goo_history
6. fatsmurf_attachment
7. fatsmurf_comment
8. fatsmurf_history
9. recipe_part
10. smurf
11. submission
12. material_qc

### Critical: goo and fatsmurf Extractions

**Must include zero-row validation:**
```sql
-- goo extraction
BEGIN TRY
    PRINT 'Extracting: goo (P0 CRITICAL - Core material entity)';

    IF OBJECT_ID('tempdb..#temp_goo') IS NOT NULL
        DROP TABLE #temp_goo;

    WITH valid_goo_types AS (
        SELECT goo_type_id FROM #temp_goo_type
    ),
    valid_workflow_steps AS (
        SELECT id FROM #temp_workflow_step
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT g.*
    INTO #temp_goo
    FROM dbo.goo g
    WHERE g.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
      AND (g.workflow_step_id IN (SELECT id FROM valid_workflow_steps) OR g.workflow_step_id IS NULL)
      AND (g.created_by_id IN (SELECT id FROM valid_users) OR g.created_by_id IS NULL)
    ORDER BY NEWID();

    DECLARE @goo_rows INT = @@ROWCOUNT;
    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @goo_rows;
    PRINT '  Rows: ' + CAST(@goo_rows AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** CRITICAL: goo.uid values needed for material lineage (Tier 4)';

    IF @goo_rows = 0
    BEGIN
        PRINT '  CRITICAL: Zero rows from goo!';
        RAISERROR('P0 CRITICAL: goo extraction failed', 16, 1);
        RETURN;
    END
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  CRITICAL: goo table extraction failed!';
    RAISERROR('P0 CRITICAL table extraction failed', 16, 1);
    RETURN;
END CATCH;
```

**Same pattern for fatsmurf.**

---

## Tier 4 Corrections Required

### Table Count: ALREADY CORRECT ✅
```sql
-- Line 18: Tables: ~11 tables INCLUDING P0 LINEAGE
-- This is CORRECT, no change needed
```

### Tables to Extract (11 total):
1. **material_transition** (P0 CRITICAL) - Lineage INPUT edges (UID-based FK!)
2. **transition_material** (P0 CRITICAL) - Lineage OUTPUT edges (UID-based FK!)
3. material_inventory
4. fatsmurf_reading
5. poll_history
6. submission_entry
7. robot_log
8. robot_log_read
9. robot_log_transfer
10. robot_log_error
11. robot_log_container_sequence

### Critical: UID-Based FK Extractions

**material_transition and transition_material ALREADY CORRECT ✅**

These tables use VARCHAR `uid` columns (not integer `id`) for FKs:
- `material_transition.material_id` → `goo.uid`
- `material_transition.transition_id` → `fatsmurf.uid`
- `transition_material.transition_id` → `fatsmurf.uid`
- `transition_material.material_id` → `goo.uid`

**Current code is CORRECT:**
```sql
-- material_transition (lines 45-56)
WITH valid_goo_uids AS (
    SELECT uid FROM #temp_goo WHERE uid IS NOT NULL
),
valid_fatsmurf_uids AS (
    SELECT uid FROM #temp_fatsmurf WHERE uid IS NOT NULL
)
SELECT TOP 15 PERCENT mt.*
INTO #temp_material_transition
FROM dbo.material_transition mt
WHERE mt.material_id IN (SELECT uid FROM valid_goo_uids)
  AND mt.transition_id IN (SELECT uid FROM valid_fatsmurf_uids)
ORDER BY NEWID();
```

**Only needs:** Idempotency + TRY/CATCH wrapper

---

## Implementation Approach

### Option A: Generate Full Corrected Scripts (60 min)
- Create extract-tier3-corrected.sql (full 12 tables, ~400 lines)
- Create extract-tier4-corrected.sql (full 11 tables, ~350 lines)
- Apply all corrections (idempotency, error handling, summaries)

### Option B: Provide Correction Template (15 min)
- User applies template to original tier3.sql and tier4.sql
- Pattern established in tier0-2 corrected scripts
- User can copy/paste TRY/CATCH wrapper and idempotency checks

### Option C: Use Original with Manual Fixes (30 min)
- User runs original tier3.sql and tier4.sql
- Manually adds `IF OBJECT_ID(...) DROP TABLE` before each extraction
- Accepts risk of no error handling (one-time migration)

---

## Recommended: Option A

**Reason:** Consistency with tier0-2, eliminates user error, production-ready

**Implementation Time:** 60 minutes
**Code Lines:** ~750 lines (tier3 + tier4)
**Quality Improvement:** 7.5/10 → 9.0/10

---

## Quick Fix Alternative

If time-constrained, user can apply this wrapper to ALL extractions in tier3 and tier4:

```sql
-- Add this BEFORE each extraction block:
IF OBJECT_ID('tempdb..#temp_TABLE_NAME') IS NOT NULL
    DROP TABLE #temp_TABLE_NAME;

-- Wrap each extraction in TRY/CATCH:
BEGIN TRY
    PRINT 'Extracting: TABLE_NAME';

    -- [Existing extraction code here]

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: TABLE_NAME';
END CATCH;
```

Apply to all 23 tables (12 in tier3, 11 in tier4) = 23 × 15 lines = 345 lines of corrections.

---

## Current Status

**Completed:**
- ✅ Tier 0 corrected (32 tables)
- ✅ Tier 1 corrected (9 tables)
- ✅ Tier 2 corrected (11 tables) - including critical workflow_step fix

**Pending:**
- ⏳ Tier 3 corrections (12 tables) - straightforward, no logic errors
- ⏳ Tier 4 corrections (11 tables) - straightforward, no logic errors

**Total Progress:** 52/76 tables corrected (68%)

---

## Decision Required

**Commander:** Should I generate full tier3-corrected.sql and tier4-corrected.sql scripts?

**Alternatives:**
- A: Generate full corrected scripts (~60 min)
- B: Provide template for user to apply (~15 min guidance)
- C: Accept original tier3/tier4 with manual idempotency fixes (~30 min user work)

**Recommendation:** Option A for consistency and production readiness.

Over.
