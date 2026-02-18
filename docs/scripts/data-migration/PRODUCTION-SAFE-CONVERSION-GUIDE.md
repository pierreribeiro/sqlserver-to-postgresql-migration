# Production-Safe Conversion Guide for Tier 3-4 Extraction Scripts

## Completed
- extract-tier0.sql - DONE
- extract-tier1.sql - DONE  
- extract-tier2.sql - DONE

## Pending
- extract-tier3.sql - IN PROGRESS
- extract-tier4.sql - IN PROGRESS

## Pattern for Converting Remaining Tiers

### 1. Header Changes

Replace header:
```sql
-- Version: 2.0 (corrected counts, idempotency, error handling)
```

With:
```sql
-- Version: 3.0 (Production-Safe: tempdb checks, NOLOCK, deterministic sampling)
```

### 2. Add Safety Preamble (after USE perseus; GO; SET NOCOUNT ON;)

```sql
-- Log session ID
DECLARE @session_id INT = @@SPID;
PRINT '========================================';
PRINT 'SESSION ID: ' + CAST(@session_id AS VARCHAR(10));
PRINT 'IMPORTANT: Save this ID for manual intervention if needed';
PRINT '========================================';
PRINT '';

-- Check tempdb free space (require minimum 2GB)
DECLARE @tempdb_free_mb INT;
SELECT @tempdb_free_mb = SUM(unallocated_extent_page_count) * 8 / 1024
FROM tempdb.sys.dm_db_file_space_usage;

PRINT 'Tempdb Free Space: ' + CAST(@tempdb_free_mb AS VARCHAR(10)) + ' MB';

IF @tempdb_free_mb < 2000
BEGIN
    RAISERROR('INSUFFICIENT TEMPDB SPACE. Free: %d MB. Required: 2000 MB. Aborting.', 16, 1, @tempdb_free_mb);
    RETURN;
END;
PRINT 'Tempdb space check: PASSED';
PRINT '';
```

### 3. Replace All Table Queries

**BEFORE:**
```sql
SELECT TOP 15 PERCENT g.*
INTO #temp_goo
FROM dbo.goo g
WHERE g.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
  AND (g.workflow_step_id IN (SELECT id FROM valid_workflow_steps) OR g.workflow_step_id IS NULL)
ORDER BY NEWID();
```

**AFTER:**
```sql
SELECT g.*
INTO #temp_goo
FROM dbo.goo g WITH (NOLOCK)
WHERE g.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
  AND (g.workflow_step_id IN (SELECT id FROM valid_workflow_steps) OR g.workflow_step_id IS NULL)
  AND (CAST(g.goo_id AS BIGINT) % 7 = 0
       OR CAST(g.goo_id AS BIGINT) % 7 = 1);
```

**Key changes:**
1. Remove `TOP 15 PERCENT`
2. Add `WITH (NOLOCK)` after table name
3. Remove `ORDER BY NEWID()`
4. Add modulo filter using **primary key column**:
   - For goo: use `goo_id`
   - For fatsmurf: use `id`
   - For standard tables with `id`: use `id`
   - Combine with existing WHERE using `AND`

### 4. Primary Key Column Reference

| Table | Primary Key Column |
|-------|-------------------|
| goo | goo_id |
| fatsmurf | id |
| goo_attachment | id |
| goo_comment | id |
| goo_history | id |
| fatsmurf_attachment | id |
| fatsmurf_comment | id |
| fatsmurf_history | id |
| recipe_part | id |
| smurf | id |
| submission | id |
| material_qc | id |
| material_transition | id |
| transition_material | id |
| material_inventory | id |
| fatsmurf_reading | id |
| poll_history | id |
| submission_entry | id |
| robot_log | id |
| robot_log_read | id |
| robot_log_transfer | id |
| robot_log_error | id |
| robot_log_container_sequence | id |

### 5. Update Summary Messages

**BEFORE:**
```sql
PRINT 'TIER 3 EXTRACTION - Starting (CORRECTED)';
PRINT 'Sample Rate: 15% (within valid FK set)';
```

**AFTER:**
```sql
PRINT 'TIER 3 EXTRACTION - Starting (PRODUCTION-SAFE)';
PRINT 'Sample Rate: ~15% (deterministic modulo-based)';
```

**Add to final summary:**
```sql
PRINT 'PRODUCTION-SAFE FEATURES:';
PRINT '  - Session ID logged for manual intervention';
PRINT '  - Tempdb space validated (2GB minimum)';
PRINT '  - NOLOCK hints applied to all queries';
PRINT '  - Deterministic modulo-based sampling (no ORDER BY NEWID)';
```

### 6. CTE Table Scans

When CTEs reference temp tables, those are already in tempdb - no NOLOCK needed:
```sql
WITH valid_goos AS (
    SELECT goo_id FROM #temp_goo  -- No NOLOCK needed for temp tables
)
```

## Quick Verification Checklist

For each converted tier script:
- [ ] Header updated to version 3.0
- [ ] Session ID logging added
- [ ] Tempdb space check added
- [ ] All `FROM dbo.table_name alias` have `WITH (NOLOCK)` added
- [ ] All `ORDER BY NEWID()` removed
- [ ] All queries have modulo filter `AND (CAST(pk AS BIGINT) % 7 = 0 OR CAST(pk AS BIGINT) % 7 = 1)`
- [ ] Summary messages updated to say "PRODUCTION-SAFE"
- [ ] Production-safe features list added to final summary

## Testing

After conversion, test with:
```sql
-- Run in test session
EXEC sp_who2; -- Note your SPID
-- Run extract-tier0.sql
-- Run extract-tier1.sql
-- Run extract-tier2.sql
-- Run extract-tier3.sql
-- Run extract-tier4.sql
-- Verify all temp tables created
SELECT name FROM tempdb.sys.tables WHERE name LIKE '#temp_%' ORDER BY name;
```

