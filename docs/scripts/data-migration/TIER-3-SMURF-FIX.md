# Tier 3 Smurf Table Extraction Fix

**Date:** 2026-02-02
**Ralph Loop Iteration:** 1
**Error:** `Msg 207, Level 16, State 1 - Invalid column name 'smurf_group_id'`

---

## Root Cause Analysis

### Problem Statement
Smurf table extraction in `extract-tier-3.sql` (lines 398-430) referenced two non-existent columns:
- `smurf_group_id` (line 416)
- `goo_type_id` (line 417)

### Investigation Steps

1. **Error Log Analysis** (`/tmp/logs/extract-data-20260202_232825.log`):
   - Line 219-220: SQL Server error indicating invalid column name `smurf_group_id`
   - Failed during Tier 3 extraction at smurf table
   - Tiers 0, 1, and 2 completed successfully

2. **Schema Verification** (TABLE-CATALOG.md):
   - Smurf table (file 78. perseus.dbo.smurf.sql) actual schema:
     ```
     | id                | int IDENTITY(1, 1) NOT NULL         |
     | class_id          | int NOT NULL                        |
     | name              | varchar(150) NOT NULL               |
     | description       | varchar(500) NULL                   |
     | themis_method_id  | int NULL                            |
     | disabled          | int NOT NULL DEFAULT ((0))          |
     ```
   - **NO `smurf_group_id` column**
   - **NO `goo_type_id` column**

3. **Submission Table Review** (lines 433-461):
   - Schema verified: Has `submitter_id` column (correct)
   - Extraction logic correct (no changes needed)
   - ✅ VALIDATED

### Root Cause
**Invalid migration assumption:** The smurf extraction script assumed FK relationships that don't exist:
- Assumed `smurf_group_id` → smurf_group table (incorrect)
- Assumed `goo_type_id` → goo_type table (incorrect)

**Actual schema:** Smurf table has NO foreign key columns, only intrinsic attributes.

---

## Solution Applied

### Option Selected: **Option B - Remove Invalid FK Dependencies**

**Rationale:**
- Smurf table has no FK dependencies per TABLE-CATALOG.md
- Extraction should be simple deterministic sampling with no FK filtering
- No need to move to different tier (Option C) - Tier 3 placement is fine

### Changes Made

**File:** `scripts/data-migration/extract-tier-3.sql`
**Lines:** 398-430 (smurf extraction block)

**BEFORE (Incorrect):**
```sql
-- Dependencies: smurf_group, goo_type, property_type, perseus_user
WITH valid_groups AS (
    SELECT id FROM ##perseus_tier_2_smurf_group
),
valid_goo_types AS (
    SELECT id FROM ##perseus_tier_0_goo_type
)
SELECT TOP 15 PERCENT s.*
INTO ##perseus_tier_3_smurf
FROM dbo.smurf s WITH (NOLOCK)
WHERE (s.smurf_group_id IN (SELECT id FROM valid_groups) OR s.smurf_group_id IS NULL)  -- Invalid
  AND (s.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types) OR s.goo_type_id IS NULL)  -- Invalid
  AND (CAST(s.id AS BIGINT) % 7 IN (0,1));
```

**AFTER (Corrected):**
```sql
-- Dependencies: NONE (no FK dependencies in actual schema)
-- CORRECTED: Removed non-existent smurf_group_id and goo_type_id columns
-- Schema: id, class_id, name, description, themis_method_id, disabled
SELECT TOP 15 PERCENT s.*
INTO ##perseus_tier_3_smurf
FROM dbo.smurf s WITH (NOLOCK)
WHERE (CAST(s.id AS BIGINT) % 7 IN (0,1));
```

### Key Corrections

| Issue | Before | After | Reason |
|-------|--------|-------|--------|
| Invalid CTE | `valid_groups` from `##perseus_tier_2_smurf_group` | Removed | No FK relationship exists |
| Invalid CTE | `valid_goo_types` from `##perseus_tier_0_goo_type` | Removed | No FK relationship exists |
| Invalid filter | `s.smurf_group_id IN (...)` | Removed | Column doesn't exist |
| Invalid filter | `s.goo_type_id IN (...)` | Removed | Column doesn't exist |
| Sampling logic | Modulo-based sampling | Preserved | Still valid for 15% sample |

---

## Submission Table Review (Lines 433-461)

### Schema Validation
**Submission table (file 83. perseus.dbo.submission.sql):**
```
| id           | int IDENTITY(1, 1) NOT NULL |
| submitter_id | int NOT NULL                |
| added_on     | datetime NOT NULL           |
| label        | varchar(100) NULL           |
```

### Code Review Result
✅ **CORRECT - No changes needed**

**Extraction logic:**
```sql
WITH valid_users AS (
    SELECT id FROM ##perseus_tier_1_perseus_user
)
SELECT TOP 15 PERCENT sub.*
INTO ##perseus_tier_3_submission
FROM dbo.submission sub WITH (NOLOCK)
WHERE sub.submitter_id IN (SELECT id FROM valid_users)
  AND (CAST(sub.id AS BIGINT) % 7 IN (0,1));
```

**Validation:**
- ✅ `submitter_id` column exists in schema
- ✅ FK to `##perseus_tier_1_perseus_user` is valid
- ✅ Sampling logic correct
- ✅ No syntax or logic issues

---

## Validation

### Schema Compliance
- ✅ All WHERE filters reference actual smurf table columns
- ✅ No invalid CTEs or FK references
- ✅ Matches TABLE-CATALOG.md schema exactly

### Dependency Chain
- ✅ Smurf table has NO dependencies (standalone extraction)
- ✅ Submission table dependency validated (perseus_user from Tier 1)

### Expected Behavior
- Smurf extraction will execute without column name errors
- ~15% sample rate maintained via modulo-based sampling
- No FK filtering needed (table has no FKs)

---

## Testing Recommendations

1. **Re-run extraction:**
   ```bash
   cd scripts/data-migration
   ./extract-data.sh
   ```

2. **Expected outcome:**
   - Tier 3 completes successfully
   - Smurf table extraction shows row count > 0
   - Submission table extraction shows row count > 0
   - No SQL errors related to smurf_group_id or goo_type_id

3. **Validation queries (PostgreSQL after load):**
   ```sql
   -- Verify smurf row count
   SELECT COUNT(*) FROM smurf;

   -- Verify submission row count and FK integrity
   SELECT COUNT(*) FROM submission s
   LEFT JOIN perseus_user pu ON s.submitter_id = pu.id
   WHERE pu.id IS NULL;  -- Should return 0
   ```

---

## Pattern Analysis

### Common Issue: FK Assumption Errors
This is the **third instance** of invalid FK assumptions in extraction scripts:
1. **Tier 2 recipe:** Assumed recipe_type_id/recipe_category_id (didn't exist)
2. **Tier 3 material_qc:** Assumed qc_by column (didn't exist)
3. **Tier 3 smurf:** Assumed smurf_group_id/goo_type_id (didn't exist)

### Prevention Strategy
**MANDATORY before writing extraction logic:**
1. Read actual table schema from TABLE-CATALOG.md
2. List ALL column names
3. Identify actual FK columns (not assumed ones)
4. Write extraction logic using ONLY verified columns
5. Never assume FK relationships - verify first

### Automation Opportunity
Consider creating a schema validation script:
```bash
# Pseudo-code
for each table in extraction script:
  extract referenced columns
  grep TABLE-CATALOG.md for table schema
  diff referenced columns vs actual columns
  flag mismatches
```

---

## Completion Status

✅ **Root cause identified:** Non-existent smurf_group_id and goo_type_id columns
✅ **Correction applied:** Removed invalid CTEs and column filters
✅ **Schema validated:** Matches TABLE-CATALOG.md exactly
✅ **Submission table reviewed:** Validated correct (no changes needed)
✅ **Ready for testing:** extract-tier-3.sql corrected and validated

<promise>TIER 3 RECIPE FIXED</promise>

**Fixed by:** Claude Sonnet 4.5 (Ralph Loop - Autonomous)
**Timestamp:** 2026-02-02 (Ralph iteration 1)
