# Tier 4 Extraction - Column Validation Report

**Date**: 2026-02-03
**Script**: `extract-tier-4.sql`
**Schema Reference**: `TABLE-CATALOG.md`

---

## Validation Methodology

For each table in Tier 4 extraction:
1. Extract all column references from SQL
2. Cross-reference against TABLE-CATALOG.md schema
3. Validate FK relationships against temp tables
4. Check sampling logic correctness

---

## Table 1: material_transition (P0 CRITICAL)

**Script Lines**: 60-94
**Schema Reference**: Line 791-800 (File 56. perseus.dbo.material_transition.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| material_id | nvarchar(50) NOT NULL |
| transition_id | nvarchar(50) NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |

### SQL References in extract-tier-4.sql
```sql
SELECT TOP 15 PERCENT mt.*
FROM dbo.material_transition mt
WHERE mt.material_id IN (...)
  AND mt.transition_id IN (...)
  AND (ABS(CHECKSUM(ISNULL(mt.material_id, '') + '|' + ISNULL(mt.transition_id, ''))) % 7 = 0)
```

### Validation
- ✅ `mt.material_id` - **EXISTS** (nvarchar(50))
- ✅ `mt.transition_id` - **EXISTS** (nvarchar(50))
- ✅ `mt.*` - Selects all columns (valid)
- ✅ FK References:
  - `material_id` → `##perseus_tier_3_goo.uid` (correct)
  - `transition_id` → `##perseus_tier_3_fatsmurf.uid` (correct)
- ✅ Sampling Logic: CHECKSUM handles nvarchar correctly

**Status**: ✅ **VALID**

---

## Table 2: transition_material (P0 CRITICAL)

**Script Lines**: 100-134
**Schema Reference**: Line 1283-1291 (File 86. perseus.dbo.transition_material.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| transition_id | nvarchar(50) NOT NULL |
| material_id | nvarchar(50) NOT NULL |

### SQL References
```sql
SELECT TOP 15 PERCENT tm.*
FROM dbo.transition_material tm
WHERE tm.transition_id IN (...)
  AND tm.material_id IN (...)
  AND (ABS(CHECKSUM(ISNULL(tm.transition_id, '') + '|' + ISNULL(tm.material_id, ''))) % 7 = 0)
```

### Validation
- ✅ `tm.transition_id` - **EXISTS** (nvarchar(50))
- ✅ `tm.material_id` - **EXISTS** (nvarchar(50))
- ✅ `tm.*` - Selects all columns (valid)
- ✅ FK References:
  - `transition_id` → `##perseus_tier_3_fatsmurf.uid` (correct)
  - `material_id` → `##perseus_tier_3_goo.uid` (correct)
- ✅ Sampling Logic: CHECKSUM handles nvarchar correctly

**Status**: ✅ **VALID**

---

## Table 3: material_inventory

**Script Lines**: 140-177
**Schema Reference**: Line 722-742 (File 52. perseus.dbo.material_inventory.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| id | int IDENTITY(1,1) NOT NULL |
| material_id | int NOT NULL |
| location_container_id | int NOT NULL |
| is_active | bit NOT NULL |
| current_volume_l | real NULL |
| current_mass_kg | real NULL |
| created_by_id | int NOT NULL |
| created_on | datetime NULL |
| updated_by_id | int NULL |
| updated_on | datetime NULL |
| allocation_container_id | int NULL |
| recipe_id | int NULL |
| comment | text NULL |
| expiration_date | date NULL |

### SQL References
```sql
SELECT TOP 15 PERCENT mi.*
FROM dbo.material_inventory mi
WHERE mi.material_id IN (SELECT id FROM valid_goos)
  AND mi.location_container_id IN (SELECT id FROM valid_containers)
  AND mi.created_by_id IN (SELECT id FROM valid_users)
  AND (mi.recipe_id IN (SELECT id FROM valid_recipes) OR mi.recipe_id IS NULL)
  AND (CAST(mi.id AS BIGINT) % 7 IN (0,1))
```

### Validation
- ✅ `mi.material_id` - **EXISTS** (int NOT NULL)
- ✅ `mi.location_container_id` - **EXISTS** (int NOT NULL)
- ✅ `mi.created_by_id` - **EXISTS** (int NOT NULL)
- ✅ `mi.recipe_id` - **EXISTS** (int NULL) - Correctly handles NULL
- ✅ `mi.id` - **EXISTS** (int IDENTITY) - Valid for sampling
- ✅ FK References:
  - `material_id` → `##perseus_tier_3_goo.id` (correct)
  - `location_container_id` → `##perseus_tier_0_container.id` (correct)
  - `created_by_id` → `##perseus_tier_1_perseus_user.id` (correct)
  - `recipe_id` → `##perseus_tier_2_recipe.id` (correct, nullable)

**Status**: ✅ **VALID**

---

## Table 4: fatsmurf_reading

**Script Lines**: 183-212
**Schema Reference**: Line 326-337 (File 27. perseus.dbo.fatsmurf_reading.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| id | int IDENTITY(1,1) NOT NULL |
| name | varchar(150) NOT NULL |
| fatsmurf_id | int NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL DEFAULT ((1)) |

### SQL References
```sql
SELECT TOP 15 PERCENT fr.*
FROM dbo.fatsmurf_reading fr
WHERE fr.fatsmurf_id IN (SELECT id FROM valid_fatsmurfs)
  AND fr.added_by IN (SELECT id FROM valid_users)
  AND (CAST(fr.id AS BIGINT) % 7 IN (0,1))
```

### Validation
- ✅ `fr.fatsmurf_id` - **EXISTS** (int NOT NULL)
- ✅ `fr.added_by` - **EXISTS** (int NOT NULL)
- ✅ `fr.id` - **EXISTS** (int IDENTITY) - Valid for sampling
- ✅ FK References:
  - `fatsmurf_id` → `##perseus_tier_3_fatsmurf.id` (correct)
  - `added_by` → `##perseus_tier_1_perseus_user.id` (correct)

**Status**: ✅ **VALID**

---

## Table 5: poll_history

**Script Lines**: 220-246
**Schema Reference**: Line 884-893 (File 61. perseus.dbo.poll_history.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| id | int IDENTITY(1,1) NOT NULL |
| history_id | int NOT NULL |
| poll_id | int NOT NULL |

### SQL References
```sql
SELECT TOP 15 PERCENT ph.*
FROM dbo.poll_history ph
WHERE ph.poll_id IN (SELECT id FROM valid_polls)
  AND (CAST(ph.id AS BIGINT) % 7 IN (0,1))
```

### Validation
- ✅ `ph.poll_id` - **EXISTS** (int NOT NULL)
- ✅ `ph.id` - **EXISTS** (int IDENTITY) - Valid for sampling
- ✅ FK References:
  - `poll_id` → `##perseus_tier_0_poll.id` (correct)
- ✅ **FIX APPLIED**: Removed invalid `fatsmurf_reading_id` column reference (line 217 comment documents this)

**Status**: ✅ **VALID** (Previously fixed)

---

## Table 6: submission_entry

**Script Lines**: 252-285
**Schema Reference**: Line 1251-1266 (File 84. perseus.dbo.submission_entry.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| id | int IDENTITY(1,1) NOT NULL |
| assay_type_id | int NOT NULL |
| material_id | int NOT NULL |
| status | varchar(19) NOT NULL |
| priority | varchar(6) NOT NULL |
| submission_id | int NOT NULL |
| prepped_by_id | int NULL |
| themis_tray_id | int NULL |
| sample_type | varchar(7) NOT NULL |

### SQL References
```sql
SELECT TOP 15 PERCENT se.*
FROM dbo.submission_entry se
WHERE se.submission_id IN (SELECT id FROM valid_submissions)
  AND se.material_id IN (SELECT id FROM valid_goos)
  AND (se.prepped_by_id IN (SELECT id FROM valid_users) OR se.prepped_by_id IS NULL)
  AND (CAST(se.id AS BIGINT) % 7 IN (0,1))
```

### Validation
- ✅ `se.submission_id` - **EXISTS** (int NOT NULL)
- ✅ `se.material_id` - **EXISTS** (int NOT NULL)
- ✅ `se.prepped_by_id` - **EXISTS** (int NULL) - Correctly handles NULL
- ✅ `se.id` - **EXISTS** (int IDENTITY) - Valid for sampling
- ✅ FK References:
  - `submission_id` → `##perseus_tier_3_submission.id` (correct)
  - `material_id` → `##perseus_tier_3_goo.id` (correct)
  - `prepped_by_id` → `##perseus_tier_1_perseus_user.id` (correct, nullable)

**Status**: ✅ **VALID**

---

## Table 7: robot_log

**Script Lines**: 291-316
**Schema Reference**: Line 990-1010 (File 68. perseus.dbo.robot_log.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| id | int IDENTITY(1,1) NOT NULL |
| class_id | int NOT NULL |
| source | varchar(250) NULL |
| created_on | datetime NOT NULL DEFAULT (getdate()) |
| log_text | varchar(max) NOT NULL |
| file_name | varchar(250) NULL |
| robot_log_checksum | varchar(32) NULL |
| started_on | datetime NULL |
| completed_on | datetime NULL |
| loaded_on | datetime NULL |
| loaded | int NOT NULL DEFAULT ((0)) |
| loadable | int NOT NULL DEFAULT ((0)) |
| robot_run_id | int NULL |
| robot_log_type_id | int NOT NULL |

### SQL References
```sql
SELECT TOP 15 PERCENT rl.*
FROM dbo.robot_log rl
WHERE rl.robot_log_type_id IN (SELECT id FROM valid_log_types)
  AND (CAST(rl.id AS BIGINT) % 7 IN (0,1))
```

### Validation
- ✅ `rl.robot_log_type_id` - **EXISTS** (int NOT NULL)
- ✅ `rl.id` - **EXISTS** (int IDENTITY) - Valid for sampling
- ✅ FK References:
  - `robot_log_type_id` → `##perseus_tier_1_robot_log_type.id` (correct)

**Status**: ✅ **VALID**

---

## Table 8: robot_log_read

**Script Lines**: 322-355
**Schema Reference**: Line 1053-1066 (File 71. perseus.dbo.robot_log_read.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| id | int IDENTITY(1,1) NOT NULL |
| robot_log_id | int NOT NULL |
| source_barcode | nvarchar(25) NOT NULL |
| property_id | int NOT NULL |
| value | varchar(25) NULL |
| source_position | nvarchar(150) NULL |
| source_material_id | int NULL |

### SQL References
```sql
SELECT TOP 15 PERCENT rlr.*
FROM dbo.robot_log_read rlr
WHERE rlr.robot_log_id IN (SELECT id FROM valid_logs)
  AND (rlr.source_material_id IN (SELECT id FROM valid_goos) OR rlr.source_material_id IS NULL)
  AND (rlr.property_id IN (SELECT id FROM valid_properties) OR rlr.property_id IS NULL)
  AND (CAST(rlr.id AS BIGINT) % 7 IN (0,1))
```

### Validation
- ✅ `rlr.robot_log_id` - **EXISTS** (int NOT NULL)
- ✅ `rlr.source_material_id` - **EXISTS** (int NULL) - Correctly handles NULL
- ✅ `rlr.property_id` - **EXISTS** (int NOT NULL)
- ✅ `rlr.id` - **EXISTS** (int IDENTITY) - Valid for sampling
- ✅ FK References:
  - `robot_log_id` → `##perseus_tier_4_robot_log.id` (correct - intra-tier dependency)
  - `source_material_id` → `##perseus_tier_3_goo.id` (correct, nullable)
  - `property_id` → `##perseus_tier_1_property.id` (correct)

**Status**: ✅ **VALID**

---

## Table 9: robot_log_transfer

**Script Lines**: 361-391
**Schema Reference**: Line 1069-1086 (File 72. perseus.dbo.robot_log_transfer.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| id | int IDENTITY(1,1) NOT NULL |
| robot_log_id | int NOT NULL |
| source_barcode | nvarchar(25) NOT NULL |
| destination_barcode | nvarchar(25) NOT NULL |
| transfer_time | datetime NULL |
| transfer_volume | varchar(25) NULL |
| source_position | nvarchar(150) NULL |
| destination_position | nvarchar(150) NULL |
| material_type_id | int NULL |
| source_material_id | int NULL |
| destination_material_id | int NULL |

### SQL References
```sql
SELECT TOP 15 PERCENT rlt.*
FROM dbo.robot_log_transfer rlt
WHERE rlt.robot_log_id IN (SELECT id FROM valid_logs)
  AND (rlt.source_material_id IN (SELECT id FROM valid_goos) OR rlt.source_material_id IS NULL)
  AND (rlt.destination_material_id IN (SELECT id FROM valid_goos) OR rlt.destination_material_id IS NULL)
  AND (CAST(rlt.id AS BIGINT) % 7 IN (0,1))
```

### Validation
- ✅ `rlt.robot_log_id` - **EXISTS** (int NOT NULL)
- ✅ `rlt.source_material_id` - **EXISTS** (int NULL) - Correctly handles NULL
- ✅ `rlt.destination_material_id` - **EXISTS** (int NULL) - Correctly handles NULL
- ✅ `rlt.id` - **EXISTS** (int IDENTITY) - Valid for sampling
- ✅ FK References:
  - `robot_log_id` → `##perseus_tier_4_robot_log.id` (correct - intra-tier dependency)
  - `source_material_id` → `##perseus_tier_3_goo.id` (correct, nullable)
  - `destination_material_id` → `##perseus_tier_3_goo.id` (correct, nullable)

**Status**: ✅ **VALID**

---

## Table 10: robot_log_error

**Script Lines**: 397-422
**Schema Reference**: Line 1041-1050 (File 70. perseus.dbo.robot_log_error.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| id | int IDENTITY(1,1) NOT NULL |
| robot_log_id | int NOT NULL |
| error_text | varchar(max) NOT NULL |

### SQL References
```sql
SELECT TOP 15 PERCENT rle.*
FROM dbo.robot_log_error rle
WHERE rle.robot_log_id IN (SELECT id FROM valid_logs)
  AND (CAST(rle.id AS BIGINT) % 7 IN (0,1))
```

### Validation
- ✅ `rle.robot_log_id` - **EXISTS** (int NOT NULL)
- ✅ `rle.id` - **EXISTS** (int IDENTITY) - Valid for sampling
- ✅ FK References:
  - `robot_log_id` → `##perseus_tier_4_robot_log.id` (correct - intra-tier dependency)

**Status**: ✅ **VALID**

---

## Table 11: robot_log_container_sequence

**Script Lines**: 428-457
**Schema Reference**: Line 1013-1024 (File 69. perseus.dbo.robot_log_container_sequence.sql)

### Schema Definition
| Column Name | Data Type |
|-------------|-----------|
| id | int IDENTITY(1,1) NOT NULL |
| robot_log_id | int NOT NULL |
| container_id | int NOT NULL |
| sequence_type_id | int NOT NULL |
| processed_on | datetime NULL |

### SQL References
```sql
SELECT TOP 15 PERCENT rlcs.*
FROM dbo.robot_log_container_sequence rlcs
WHERE rlcs.robot_log_id IN (SELECT id FROM valid_logs)
  AND rlcs.container_id IN (SELECT id FROM valid_containers)
  AND (CAST(rlcs.id AS BIGINT) % 7 IN (0,1))
```

### Validation
- ✅ `rlcs.robot_log_id` - **EXISTS** (int NOT NULL)
- ✅ `rlcs.container_id` - **EXISTS** (int NOT NULL)
- ✅ `rlcs.id` - **EXISTS** (int IDENTITY) - Valid for sampling
- ✅ FK References:
  - `robot_log_id` → `##perseus_tier_4_robot_log.id` (correct - intra-tier dependency)
  - `container_id` → `##perseus_tier_0_container.id` (correct)

**Status**: ✅ **VALID**

---

## Summary

### Tables Validated: 11/11

| # | Table | Status | Issues |
|---|-------|--------|--------|
| 1 | material_transition | ✅ VALID | None |
| 2 | transition_material | ✅ VALID | None |
| 3 | material_inventory | ✅ VALID | None |
| 4 | fatsmurf_reading | ✅ VALID | None |
| 5 | poll_history | ✅ VALID | Previously fixed (removed invalid fatsmurf_reading_id) |
| 6 | submission_entry | ✅ VALID | None |
| 7 | robot_log | ✅ VALID | None |
| 8 | robot_log_read | ✅ VALID | None |
| 9 | robot_log_transfer | ✅ VALID | None |
| 10 | robot_log_error | ✅ VALID | None |
| 11 | robot_log_container_sequence | ✅ VALID | None |

### Column Reference Validation: ✅ 100% PASS

**Total Columns Referenced**: 33 column references across 11 tables
**Valid References**: 33/33 (100%)
**Invalid References**: 0/33 (0%)

### FK Dependency Validation: ✅ PASS

All foreign key references correctly point to prerequisite temp tables:
- Tier 0: `container`, `poll`
- Tier 1: `perseus_user`, `robot_log_type`, `property`
- Tier 2: `recipe`
- Tier 3: `goo`, `fatsmurf`, `submission`
- Tier 4 (intra-tier): `robot_log` → robot_log child tables

### Sampling Logic Validation: ✅ PASS

- **UID-based tables** (material_transition, transition_material): Use `ABS(CHECKSUM(...))` correctly for nvarchar sampling
- **ID-based tables** (all others): Use `CAST(id AS BIGINT) % 7 IN (0,1)` for deterministic sampling

---

## Conclusion

✅ **ALL TIER 4 EXTRACTIONS ARE VALID**

- No missing columns detected
- No incorrect column references
- All FK relationships validated
- All NULL handling correct
- Sampling logic appropriate for data types
- Prerequisite checks in place

**READY FOR PRODUCTION EXECUTION**
