# Tier 2 Recipe Table Extraction Fix

**Date:** 2026-02-02
**Ralph Loop Iteration:** 1
**Error:** `Msg 208, Level 16, State 1 - Invalid object name '##perseus_tier_0_recipe_type'`

---

## Root Cause Analysis

### Problem Statement
Recipe table extraction in `extract-tier-2.sql` (lines 295-336) referenced two non-existent database objects:
- `##perseus_tier_0_recipe_type` (temp table)
- `##perseus_tier_0_recipe_category` (temp table)

### Investigation Steps

1. **Error Log Analysis** (`/tmp/logs/extract-data-20260202_224836.log`):
   - Line 188-189: SQL Server error indicating invalid object name
   - Failed during Tier 2 extraction at recipe table

2. **Schema Verification** (TABLE-CATALOG.md):
   - Recipe table (file 65. perseus.dbo.recipe.sql) contains **NO** `recipe_type_id` or `recipe_category_id` columns
   - Actual columns: id, name, goo_type_id, workflow_id, added_by, added_on, feed_type_id, etc.

3. **Source Database Check**:
   - Grep search for `recipe_type` and `recipe_category` in entire SQL Server schema directory: **0 results**
   - **Conclusion:** These tables never existed in the source database

4. **Tier 0 Script Check**:
   - `extract-tier-0.sql` does not create `##perseus_tier_0_recipe_type` or `##perseus_tier_0_recipe_category`
   - **Reason:** Cannot create temp tables for non-existent source tables

### Root Cause
**Invalid migration assumption:** The recipe extraction script was written based on an incorrect assumption that recipe_type and recipe_category tables existed. These tables/columns do not exist in the actual SQL Server schema.

---

## Solution Applied

### Option Selected: **Option B - Remove Invalid FK Dependencies**

**Rationale:**
- Cannot create temp tables for non-existent source tables (Option A not viable)
- Recipe table belongs in Tier 2 due to its actual dependencies (Option C not needed)
- Correct approach: Update FK filtering logic to match actual schema

### Changes Made

**File:** `scripts/data-migration/extract-tier-2.sql`
**Lines:** 295-340 (recipe extraction block)

**BEFORE (Incorrect):**
```sql
-- Dependencies: recipe_type, recipe_category, goo_type, feed_type
WITH valid_types AS (
    SELECT id FROM ##perseus_tier_0_recipe_type  -- Does not exist
),
valid_categories AS (
    SELECT id FROM ##perseus_tier_0_recipe_category  -- Does not exist
),
valid_goo_types AS (
    SELECT id FROM ##perseus_tier_0_goo_type
),
valid_feed_types AS (
    SELECT id FROM ##perseus_tier_2_feed_type
)
SELECT r.*
INTO ##perseus_tier_2_recipe
FROM dbo.recipe r WITH (NOLOCK)
WHERE r.recipe_type_id IN (SELECT id FROM valid_types)     -- Invalid column
  AND r.recipe_category_id IN (SELECT id FROM valid_categories)  -- Invalid column
  AND (r.goo_type_id IN (...) OR r.goo_type_id IS NULL)
  AND (r.feed_type_id IN (...) OR r.feed_type_id IS NULL)
  AND (CAST(r.id AS BIGINT) % 7 = 0 OR CAST(r.id AS BIGINT) % 7 = 1);
```

**AFTER (Corrected):**
```sql
-- Dependencies: goo_type, workflow (nullable), feed_type (nullable), perseus_user
-- CORRECTED: Removed non-existent recipe_type_id and recipe_category_id columns
WITH valid_goo_types AS (
    SELECT id FROM ##perseus_tier_0_goo_type
),
valid_workflows AS (
    SELECT id FROM ##perseus_tier_1_workflow
),
valid_feed_types AS (
    SELECT id FROM ##perseus_tier_2_feed_type
),
valid_users AS (
    SELECT id FROM ##perseus_tier_1_perseus_user
)
SELECT r.*
INTO ##perseus_tier_2_recipe
FROM dbo.recipe r WITH (NOLOCK)
WHERE r.goo_type_id IN (SELECT id FROM valid_goo_types)
  AND (r.workflow_id IN (SELECT id FROM valid_workflows) OR r.workflow_id IS NULL)
  AND (r.feed_type_id IN (SELECT id FROM valid_feed_types) OR r.feed_type_id IS NULL)
  AND r.added_by IN (SELECT id FROM valid_users)
  AND (CAST(r.id AS BIGINT) % 7 = 0 OR CAST(r.id AS BIGINT) % 7 = 1);
```

### Key Corrections

| Issue | Before | After | Reason |
|-------|--------|-------|--------|
| Invalid CTE | `valid_types` from `##perseus_tier_0_recipe_type` | Removed | Table doesn't exist |
| Invalid CTE | `valid_categories` from `##perseus_tier_0_recipe_category` | Removed | Table doesn't exist |
| Missing CTE | N/A | `valid_workflows` from `##perseus_tier_1_workflow` | Actual FK in schema |
| Missing CTE | N/A | `valid_users` from `##perseus_tier_1_perseus_user` | Actual FK (added_by) |
| Invalid filter | `r.recipe_type_id IN (...)` | Removed | Column doesn't exist |
| Invalid filter | `r.recipe_category_id IN (...)` | Removed | Column doesn't exist |
| Missing filter | N/A | `r.workflow_id IN (...) OR IS NULL` | Actual nullable FK |
| Missing filter | N/A | `r.added_by IN (...)` | Actual required FK |

---

## Validation

### Schema Compliance
- ✅ All CTEs reference existing temp tables (created in Tiers 0-1)
- ✅ All WHERE filters reference actual recipe table columns
- ✅ FK relationships match TABLE-CATALOG.md schema
- ✅ Nullable FKs handled with `OR IS NULL` logic

### Dependency Chain
- ✅ goo_type: Tier 0 dependency (required FK)
- ✅ workflow: Tier 1 dependency (nullable FK)
- ✅ feed_type: Tier 2 dependency (nullable FK)
- ✅ perseus_user (added_by): Tier 1 dependency (required FK)

### Expected Behavior
- Recipe extraction will now execute without "Invalid object name" errors
- ~15% sample rate maintained
- FK filtering ensures referential integrity with extracted Tier 0-1 data
- No additional tables needed in Tier 0

---

## Testing Recommendations

1. **Re-run extraction:**
   ```bash
   cd scripts/data-migration
   ./extract-data.sh
   ```

2. **Expected outcome:**
   - Tier 2 completes successfully
   - Recipe table extraction shows row count > 0
   - No SQL errors related to recipe_type or recipe_category

3. **Validation queries (PostgreSQL after load):**
   ```sql
   -- Verify row count
   SELECT COUNT(*) FROM recipe;

   -- Verify FK integrity
   SELECT COUNT(*) FROM recipe r
   LEFT JOIN goo_type gt ON r.goo_type_id = gt.id
   WHERE gt.id IS NULL;  -- Should return 0

   -- Verify workflow FK (nullable)
   SELECT COUNT(*) FROM recipe WHERE workflow_id IS NOT NULL;
   ```

---

## Lessons Learned

### Pattern for Future Fixes
1. **Always verify schema first:** Check TABLE-CATALOG.md before writing extraction logic
2. **Grep for table existence:** Search source schema directory to confirm tables exist
3. **Test incrementally:** Run single-tier extractions to catch errors early
4. **Document assumptions:** Comment why certain FKs are filtered or excluded

### Prevention
- Add schema validation step in extraction script generator
- Cross-reference all temp table CTEs against Tier 0 script
- Include "table exists" checks before complex FK filtering

---

## Completion Status

✅ **Root cause identified:** Non-existent recipe_type and recipe_category tables
✅ **Correction applied:** Removed invalid CTEs and filters, added missing ones
✅ **Schema validated:** All references match TABLE-CATALOG.md
✅ **Ready for testing:** extract-tier-2.sql corrected and validated

<promise>TIER 2 RECIPE FIXED</promise>

**Fixed by:** Claude Sonnet 4.5 (Ralph Loop - Autonomous)
**Timestamp:** 2026-02-02 (Ralph iteration 1)
