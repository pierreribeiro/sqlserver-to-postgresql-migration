# CITEXT Conversion -- Functions Update Guide

**User Story:** Deferred from US7 (Column Conversion to CITEXT)
**Audience:** Human development team AND future Claude agent worktree
**Status:** PENDING -- to be executed in a future User Story
**Created:** 2026-03-17

---

## Context

US7 converted **172 VARCHAR columns to CITEXT** across 65+ tables in the Perseus database. The **25 functions** (15 table-valued, 10 scalar) have NOT yet been updated. Functions are **more critical than procedures** because:

1. **Return types matter** -- table-valued functions return result sets with column types that callers depend on
2. **Inline usage** -- functions are used in SELECT lists, WHERE clauses, and JOINs where type mismatches cause implicit casts
3. **View dependencies** -- several views call functions, creating a type chain: table (CITEXT) --> function return (VARCHAR?) --> view column (?)
4. **Index compatibility** -- if a function return is used in an index expression, the type must match

**Important:** Functions have NOT yet been converted to PostgreSQL. They exist only in the original SQL Server source (`source/original/sqlserver/11.create-routine/`) and AWS SCT baseline (`source/original/pgsql-aws-sct-converted/19.create-function/`). The refactored directory (`source/building/pgsql/refactored/19.create-function/`) is currently empty. The function conversion (US2) should incorporate CITEXT types from the start rather than converting from VARCHAR after the fact.

---

## Key CITEXT Columns Referenced by Functions

| Table | Column | Referenced By Functions |
|---|---|---|
| `goo` | `uid` | McGetUpStream, McGetDownStream, McGetUpStreamByList, McGetDownStreamByList, GetUpstreamMasses, GetUnProcessedUpStream, GetExperiment, GetHermesUid |
| `goo` | `name` | GetExperiment, GetFermentationFatSmurf, GetHermesExperiment |
| `material_transition` | `material_id` | (via `translated` view) McGet* family |
| `material_transition` | `transition_id` | (via `translated` view) McGet* family |
| `transition_material` | `material_id` | (via `translated` view) McGet* family |
| `transition_material` | `transition_id` | (via `translated` view) McGet* family |
| `m_upstream` | `start_point`, `end_point`, `path` | McGetUpStream, McGetUpStreamByList, ReversePath (path values) |
| `m_downstream` | `start_point`, `end_point`, `path` | McGetDownStream, McGetDownStreamByList, ReversePath (path values) |
| `fatsmurf` | `uid`, `name` | GetFermentationFatSmurf |
| `container` | `uid`, `name` | GetUpStreamContainers, GetDownStreamContainers |
| `robot_log` | `source`, `file_name` | GetReadCombos, GetTransferCombos, GetSampleTime |
| `robot_log_read` | `source_barcode`, `value` | GetReadCombos |
| `robot_log_transfer` | `source_barcode`, `destination_barcode` | GetTransferCombos |

---

## Function-by-Function Analysis

### Category 1: McGet* Family (P0 CRITICAL -- 4 functions)

These are the core material lineage traversal functions. They return table results with `start_point`, `end_point`, `path` columns that are now CITEXT in the underlying tables.

#### 1.1 McGetUpStream

**Original:** `source/original/sqlserver/11.create-routine/38.perseus.dbo.McGetUpStream.sql`
**AWS SCT:** `source/original/pgsql-aws-sct-converted/19.create-function/25.perseus.mcgetupstream.sql`

**Signature changes:**
- Parameter: `@StartPoint VARCHAR(50)` --> `p_start_point CITEXT`
- Return table columns:
  - `start_point VARCHAR(50)` --> `start_point CITEXT`
  - `end_point VARCHAR(50)` --> `end_point CITEXT`
  - `path VARCHAR(MAX)` --> `path CITEXT`
  - `neighbor VARCHAR(50)` --> `neighbor CITEXT`
  - `level INT` --> stays INT

**Internal changes:**
- Recursive CTE anchor/member variables storing uid values --> CITEXT
- Path concatenation (`||`) produces CITEXT when inputs are CITEXT (no change needed)
- Remove any explicit `::VARCHAR` casts on uid/path values

**Dependencies:** `translated` view (already recreated with CITEXT columns in US7)

---

#### 1.2 McGetDownStream

**Original:** `source/original/sqlserver/11.create-routine/35.perseus.dbo.McGetDownStream.sql`
**AWS SCT:** `source/original/pgsql-aws-sct-converted/19.create-function/22.perseus.mcgetdownstream.sql`

**Signature changes:** Same pattern as McGetUpStream (mirror function)
- Parameter: `@StartPoint VARCHAR(50)` --> `p_start_point CITEXT`
- Return table: all uid/path columns --> CITEXT

---

#### 1.3 McGetUpStreamByList

**Original:** `source/original/sqlserver/11.create-routine/39.perseus.dbo.McGetUpStreamByList.sql`
**AWS SCT:** `source/original/pgsql-aws-sct-converted/19.create-function/26.perseus.mcgetupstreambylist.sql`

**Signature changes:**
- Parameter: `@StartPoint GooList READONLY` --> temp table or CITEXT[] array with CITEXT uid values
- Return table: same as McGetUpStream (all uid/path columns --> CITEXT)

**Special note:** GooList TVP conversion to PostgreSQL pattern. The uid column in the GooList type/temp table must be CITEXT to match `goo.uid`.

---

#### 1.4 McGetDownStreamByList

**Original:** `source/original/sqlserver/11.create-routine/36.perseus.dbo.McGetDownStreamByList.sql`
**AWS SCT:** `source/original/pgsql-aws-sct-converted/19.create-function/23.perseus.mcgetdownstreambylist.sql`

**Signature changes:** Same pattern as McGetUpStreamByList (mirror function)

---

### Category 2: Get* Family -- Legacy Hierarchy (10 functions, MEDIUM priority)

These functions use nested sets model and `goo_relationship` table. They primarily work with INTEGER IDs but some accept/return VARCHAR uid values.

#### 2.1 GetUpStream

**Original:** `source/original/sqlserver/11.create-routine/31.perseus.dbo.GetUpStream.sql`

**Parameter:** `@StartPoint INT` --> stays INT (uses goo.id, not goo.uid)
**Return table:** `start_point INT, end_point INT, level INT` --> stays INT

**CITEXT impact:** LOW -- works with integer IDs, not uid strings

---

#### 2.2 GetDownStream

**Original:** `source/original/sqlserver/11.create-routine/25.perseus.dbo.GetDownStream.sql`

**CITEXT impact:** LOW -- same as GetUpStream (integer-based)

---

#### 2.3 GetUpStreamFamily

**Original:** `source/original/sqlserver/11.create-routine/33.perseus.dbo.GetUpStreamFamily.sql`

**CITEXT impact:** LOW -- integer-based hierarchy traversal

---

#### 2.4 GetDownStreamFamily

**Original:** `source/original/sqlserver/11.create-routine/27.perseus.dbo.GetDownStreamFamily.sql`

**CITEXT impact:** LOW -- integer-based hierarchy traversal

---

#### 2.5 GetUpStreamContainers

**Original:** `source/original/sqlserver/11.create-routine/32.perseus.dbo.GetUpStreamContainers.sql`

**CITEXT impact:** MEDIUM -- may reference `container.uid` (now CITEXT) and `container.name` (now CITEXT)
- Review return columns for container name/uid values

---

#### 2.6 GetDownStreamContainers

**Original:** `source/original/sqlserver/11.create-routine/26.perseus.dbo.GetDownStreamContainers.sql`

**CITEXT impact:** MEDIUM -- mirror of GetUpStreamContainers

---

#### 2.7 GetUnProcessedUpStream

**Original:** `source/original/sqlserver/11.create-routine/30.perseus.dbo.GetUnProcessedUpStream.sql`

**CITEXT impact:** MEDIUM -- may filter on `goo.uid` or status columns

---

#### 2.8 GetUpstreamMasses

**Original:** `source/original/sqlserver/11.create-routine/34.perseus.dbo.GetUpstreamMasses.sql`

**Signature changes:**
- Parameter: `@StartPoint NVARCHAR(50)` --> `p_start_point CITEXT` (references goo.uid pattern)
- Return table: `end_point NVARCHAR(50)` --> `end_point CITEXT`

**CITEXT impact:** HIGH -- accepts and returns uid-like values
**Special note:** Contains CURSOR logic that must be refactored to set-based operations (separate from CITEXT changes)

---

#### 2.9 GetReadCombos

**Original:** `source/original/sqlserver/11.create-routine/28.perseus.dbo.GetReadCombos.sql`

**CITEXT impact:** MEDIUM -- references `robot_log_read.source_barcode` (now CITEXT), `robot_log_read.value` (now CITEXT)

---

#### 2.10 GetTransferCombos

**Original:** `source/original/sqlserver/11.create-routine/29.perseus.dbo.GetTransferCombos.sql`

**CITEXT impact:** MEDIUM -- references `robot_log_transfer.source_barcode`, `destination_barcode` (now CITEXT)

---

### Category 3: Experiment/Hermes Functions (5 functions, MEDIUM priority)

#### 3.1 GetExperiment

**Original:** `source/original/sqlserver/11.create-routine/15.perseus.dbo.GetExperiment.sql`

**CITEXT impact:** MEDIUM -- may extract experiment IDs from `goo.uid` (now CITEXT). Return type likely needs updating if it returns parsed uid values.

---

#### 3.2 GetHermesExperiment

**Original:** `source/original/sqlserver/11.create-routine/17.perseus.dbo.GetHermesExperiment.sql`

**CITEXT impact:** MEDIUM -- references `goo.name` (now CITEXT) and potentially hermes schema columns (FOREIGN TABLE -- do NOT change remote types)

---

#### 3.3 GetHermesRun

**Original:** `source/original/sqlserver/11.create-routine/18.perseus.dbo.GetHermesRun.sql`

**CITEXT impact:** LOW-MEDIUM -- string parsing function

---

#### 3.4 GetHermesUid

**Original:** `source/original/sqlserver/11.create-routine/19.perseus.dbo.GetHermesUid.sql`

**CITEXT impact:** MEDIUM -- returns uid values that are now CITEXT in underlying tables

---

#### 3.5 GetFermentationFatSmurf

**Original:** `source/original/sqlserver/11.create-routine/16.perseus.dbo.GetFermentationFatSmurf.sql`

**CITEXT impact:** MEDIUM -- references `fatsmurf.uid` (now CITEXT), `fatsmurf.name` (now CITEXT), `smurf.name` (now CITEXT)

---

#### 3.6 GetSampleTime

**Original:** `source/original/sqlserver/11.create-routine/20.perseus.dbo.GetSampleTime.sql`

**CITEXT impact:** LOW -- primarily date/time logic

---

### Category 4: Utility Functions (4 functions, LOW priority)

#### 4.1 ReversePath

**Original:** `source/original/sqlserver/11.create-routine/21.perseus.dbo.ReversePath.sql`

**Signature changes:**
- Parameter: `@source VARCHAR(MAX)` --> `p_source CITEXT` (processes path values from m_upstream/m_downstream)
- Return: `VARCHAR(MAX)` --> `CITEXT`

**CITEXT impact:** MEDIUM -- path values are now CITEXT. The function performs string manipulation that works identically on CITEXT.

---

#### 4.2 RoundDateTime

**Original:** `source/original/sqlserver/11.create-routine/22.perseus.dbo.RoundDateTime.sql`

**CITEXT impact:** NONE -- pure date/time function, no VARCHAR columns

---

#### 4.3 initCaps

**Original:** `source/original/sqlserver/11.create-routine/23.perseus.dbo.initCaps.sql`

**CITEXT impact:** LOW -- string utility. Consider whether PostgreSQL built-in `initcap()` suffices. If a custom function is kept, input/output should be CITEXT if callers pass CITEXT values.

---

#### 4.4 udf_datetrunc

**Original:** `source/original/sqlserver/11.create-routine/24.perseus.dbo.udf_datetrunc.sql`

**CITEXT impact:** NONE -- pure date function. Consider replacing with PostgreSQL built-in `date_trunc()`.

---

### Category 5: Combined/Wrapper Function (1 function)

#### 5.1 McGetUpDownStream

**Original:** `source/original/sqlserver/11.create-routine/37.perseus.dbo.McGetUpDownStream.sql`

**Signature changes:**
- Parameter: `@StartPoint VARCHAR(50)` --> `p_start_point CITEXT`
- Return table: all uid/path columns --> CITEXT

**CITEXT impact:** HIGH -- wraps McGetUpStream + McGetDownStream, must match their return types

---

## Return Type Summary

Functions whose return types MUST change to CITEXT:

| Function | Return Column | Old Type | New Type |
|---|---|---|---|
| McGetUpStream | start_point, end_point, neighbor | VARCHAR(50) | CITEXT |
| McGetUpStream | path | VARCHAR(MAX) | CITEXT |
| McGetDownStream | start_point, end_point, neighbor | VARCHAR(50) | CITEXT |
| McGetDownStream | path | VARCHAR(MAX) | CITEXT |
| McGetUpStreamByList | start_point, end_point, neighbor | VARCHAR(50) | CITEXT |
| McGetUpStreamByList | path | VARCHAR(MAX) | CITEXT |
| McGetDownStreamByList | start_point, end_point, neighbor | VARCHAR(50) | CITEXT |
| McGetDownStreamByList | path | VARCHAR(MAX) | CITEXT |
| McGetUpDownStream | start_point, end_point, neighbor | VARCHAR(50) | CITEXT |
| McGetUpDownStream | path | VARCHAR(MAX) | CITEXT |
| GetUpstreamMasses | end_point | NVARCHAR(50) | CITEXT |
| ReversePath | (scalar return) | VARCHAR(MAX) | CITEXT |

---

## Testing Checklist

For EACH function after updating:

- [ ] **Syntax validation:** `psql -d perseus_dev -f <function>.sql` deploys without errors
- [ ] **Return type verification:** Query `pg_catalog.pg_proc` and `information_schema.routines` to confirm return types
- [ ] **Parameter type verification:** Confirm input parameter types via catalog queries
- [ ] **Unit tests pass:** Run `tests/unit/test_<function>.sql` (create if not existing)
- [ ] **Case-insensitive behavior:** Call function with mixed-case uid values, verify consistent results
- [ ] **View compatibility:** After function deployment, verify all dependent views still compile
- [ ] **Procedure compatibility:** Verify procedures that call each function still work
- [ ] **Performance regression:** EXPLAIN ANALYZE on function calls -- within +/-20% baseline
- [ ] **Path concatenation:** For McGet* functions, verify path strings are built correctly with CITEXT concatenation
- [ ] **GooList compatibility:** For ByList functions, verify temp table / array input with CITEXT uid values

### Priority Order for Conversion and Testing

1. **P0 Critical (convert first):** McGetUpStream, McGetDownStream, McGetUpStreamByList, McGetDownStreamByList
2. **P1 Wrapper:** McGetUpDownStream
3. **P1 Mass calculation:** GetUpstreamMasses, GetUnProcessedUpStream
4. **P2 Container:** GetUpStreamContainers, GetDownStreamContainers
5. **P2 Experiment:** GetExperiment, GetHermesExperiment, GetHermesRun, GetHermesUid, GetFermentationFatSmurf, GetSampleTime
6. **P2 Robot:** GetReadCombos, GetTransferCombos
7. **P3 Legacy hierarchy:** GetUpStream, GetDownStream, GetUpStreamFamily, GetDownStreamFamily
8. **P3 Utility:** ReversePath, initCaps, RoundDateTime, udf_datetrunc

---

## FDW Boundary Warning

Functions that query foreign tables (Hermes schema) must NOT change the foreign table column types. Apply explicit casts at the boundary:

```sql
-- Example: reading from foreign table into CITEXT variable
SELECT uid::CITEXT INTO v_local_uid
FROM hermes.run
WHERE run_id = p_run_id;
```

---

## Reference Files

- **CITEXT candidate columns:** `prompts/columns_citext_candidates.txt` (172 ALTER statements)
- **Function dependency analysis:** `docs/code-analysis/dependency/dependency-analysis-lote2-functions.md`
- **Original SQL Server functions:** `source/original/sqlserver/11.create-routine/` (files 15-39)
- **AWS SCT converted functions:** `source/original/pgsql-aws-sct-converted/19.create-function/`
- **Refactored functions target:** `source/building/pgsql/refactored/19.create-function/` (currently empty)
- **Dependency analysis:** `docs/post-migration/citext-dependency-analysis.md`
- **Procedures guide (companion):** `docs/post-migration/CITEXT-PROCEDURES-UPDATE-GUIDE.md`
