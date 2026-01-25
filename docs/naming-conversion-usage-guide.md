# Naming Conversion Usage Guide
## Quick Reference for Application Team

**Project:** Perseus Database Migration - SQL Server → PostgreSQL 17
**Document Version:** 1.0
**Created:** 2026-01-25
**Audience:** Application developers, QA engineers, DevOps

---

## 🎯 Quick Start

### Find an Object Name Conversion

#### Option 1: Search by SQL Server Name
```bash
grep -i "AddArc" docs/naming-conversion-map.csv
```
**Result:**
```
procedure,AddArc,addarc,dbo,perseus,P0 Critical,,COMPLETE,P0 Critical - Material lineage creation
```
**PostgreSQL name:** `perseus.addarc`

#### Option 2: Search by PostgreSQL Name
```bash
grep -i "mcgetupstream" docs/naming-conversion-map.csv
```
**Result:**
```
function,McGetUpStream,mcgetupstream,dbo,perseus,P0,8/10,PENDING,Single material upstream
```
**SQL Server name:** `dbo.McGetUpStream`

#### Option 3: Using Python Script
```python
from scripts.automation.generate_naming_map import NamingConverter

converter = NamingConverter()
pg_name, notes = converter.convert_name("GetMaterialByRunProperties", "procedure")
print(f"PostgreSQL name: {pg_name}")  # get_material_by_run_properties
```

---

## 📋 Common Conversions

### Stored Procedures (15 Complete)

| SQL Server | PostgreSQL | Status | Priority |
|------------|-----------|--------|----------|
| `dbo.AddArc` | `perseus.addarc` | COMPLETE | P0 Critical |
| `dbo.RemoveArc` | `perseus.removearc` | COMPLETE | P0 Critical |
| `dbo.ReconcileMUpstream` | `perseus.reconcile_mupstream` | COMPLETE | P0 Critical |
| `dbo.sp_MoveNode` | `perseus.move_node` | COMPLETE | P2 Medium |
| `dbo.usp_UpdateMUpstream` | `perseus.update_mupstream` | COMPLETE | P2 Medium |
| `dbo.GetMaterialByRunProperties` | `perseus.get_material_by_run_properties` | COMPLETE | P1 Medium |

**Pattern:**
- Remove `sp_` or `usp_` prefix
- Convert to snake_case
- Schema: `dbo` → `perseus`

### Functions (25 Pending)

| SQL Server | PostgreSQL | Priority | Complexity |
|------------|-----------|----------|------------|
| `dbo.McGetUpStream()` | `perseus.mcgetupstream()` | P0 | 8/10 |
| `dbo.McGetDownStream()` | `perseus.mcgetdownstream()` | P0 | 8/10 |
| `dbo.McGetUpStreamByList()` | `perseus.mcgetupstreambylist()` | P0 | 9/10 |
| `dbo.GetUpStream()` | `perseus.getupstream()` | P1 | 7/10 |
| `dbo.GetMaterialByRunProperties()` | `perseus.get_material_by_run_properties()` | P1 | 5/10 |

**Special Cases:**
- **Mc prefix:** `McGetUpStream` → `mcgetupstream` (lowercase, NO underscores)
- **Utility functions:** `initCaps` → Use PostgreSQL `initcap()` built-in instead

### Views (22 Pending)

| SQL Server | PostgreSQL | Type | Priority |
|------------|-----------|------|----------|
| `dbo.translated` | `perseus.translated` | MATERIALIZED VIEW | P0 |
| `dbo.upstream` | `perseus.upstream` | Regular view | P1 |
| `dbo.downstream` | `perseus.downstream` | Regular view | P1 |
| `dbo.vw_lot` | `perseus.vw_lot` | Regular view | P2 |

**Notes:**
- `translated`: SQL Server INDEXED VIEW → PostgreSQL MATERIALIZED VIEW
- Most views: Keep name as-is (already snake_case or `vw_` prefix)

### Tables (12 Core Tables Documented)

| SQL Server | PostgreSQL | Priority | Notes |
|------------|-----------|----------|-------|
| `dbo.goo` | `perseus.goo` | P0 | Material master table |
| `dbo.material_transition` | `perseus.material_transition` | P0 | Parent→Transition edges |
| `dbo.transition_material` | `perseus.transition_material` | P0 | Transition→Child edges |
| `dbo.m_upstream` | `perseus.m_upstream` | P0 | Cached upstream graph |
| `dbo.m_downstream` | `perseus.m_downstream` | P0 | Cached downstream graph |

**Pattern:**
- Already snake_case → Keep as-is
- PascalCase → Convert to snake_case

### Types (1 Type)

| SQL Server | PostgreSQL | Pattern |
|------------|-----------|---------|
| `dbo.GooList` (TVP) | `CREATE TEMPORARY TABLE tmp_goo_list` | TVP → TEMP TABLE |

**Usage Change:**
```sql
-- SQL Server (Table-Valued Parameter)
DECLARE @materials GooList;
INSERT INTO @materials (uid) VALUES (123), (456);
EXEC dbo.McGetUpStreamByList @materials;

-- PostgreSQL (Temporary Table)
CREATE TEMPORARY TABLE tmp_goo_list (
    goo_id INTEGER PRIMARY KEY
) ON COMMIT DROP;
INSERT INTO tmp_goo_list (goo_id) VALUES (123), (456);
SELECT * FROM perseus.mcgetupstreambylist();  -- Reads from tmp_goo_list
```

---

## 🔄 Schema Mapping

### Default Schema
```
SQL Server: dbo
PostgreSQL: perseus
```

### External Schemas (Preserved)
```
SQL Server: hermes     → PostgreSQL: hermes
SQL Server: sqlapps    → PostgreSQL: sqlapps (via FDW)
SQL Server: deimeter   → PostgreSQL: deimeter (via FDW)
```

### Always Use Schema-Qualified Names

**✅ Correct:**
```sql
SELECT * FROM perseus.goo WHERE goo_id = 123;
SELECT * FROM hermes.run WHERE experiment_id = 456;
CALL perseus.addarc(123, 456, 789);
```

**❌ Incorrect:**
```sql
SELECT * FROM goo WHERE goo_id = 123;  -- Missing schema
CALL addarc(123, 456, 789);             -- Missing schema
```

---

## 🛠️ Application Code Updates

### Example 1: Update Procedure Call

**Before (SQL Server):**
```csharp
// C# application code
var command = new SqlCommand("EXEC dbo.AddArc @materialId, @transitionId, @childId", connection);
command.Parameters.AddWithValue("@materialId", 123);
command.Parameters.AddWithValue("@transitionId", 456);
command.Parameters.AddWithValue("@childId", 789);
command.ExecuteNonQuery();
```

**After (PostgreSQL):**
```csharp
// C# application code with Npgsql
var command = new NpgsqlCommand("CALL perseus.addarc($1, $2, $3)", connection);
command.Parameters.AddWithValue(123);
command.Parameters.AddWithValue(456);
command.Parameters.AddWithValue(789);
command.ExecuteNonQuery();
```

**Changes:**
1. `EXEC` → `CALL`
2. `dbo.AddArc` → `perseus.addarc`
3. `@param` → `$1, $2, $3` (positional parameters)

### Example 2: Update Function Call

**Before (SQL Server):**
```sql
-- SQL query in application
SELECT * FROM dbo.McGetUpStream('MAT-123')
WHERE level <= 3;
```

**After (PostgreSQL):**
```sql
-- SQL query in application
SELECT * FROM perseus.mcgetupstream('MAT-123')
WHERE level <= 3;
```

**Changes:**
1. `dbo.McGetUpStream` → `perseus.mcgetupstream`
2. Function name lowercase
3. Schema-qualified

### Example 3: Update View Reference

**Before (SQL Server):**
```sql
-- SQL query in application
SELECT source_material, destination_material
FROM dbo.translated
WHERE destination_material = 'MAT-456';
```

**After (PostgreSQL):**
```sql
-- SQL query in application
SELECT source_material, destination_material
FROM perseus.translated
WHERE destination_material = 'MAT-456';
```

**Changes:**
1. `dbo.translated` → `perseus.translated`
2. Schema-qualified

---

## 🔍 Search & Filter Commands

### List All Objects by Type

```bash
# List all procedures
awk -F, '$1=="procedure" {print $2}' docs/naming-conversion-map.csv

# List all functions
awk -F, '$1=="function" {print $2}' docs/naming-conversion-map.csv

# List all views
awk -F, '$1=="view" {print $2}' docs/naming-conversion-map.csv
```

### List P0 Critical Objects

```bash
# All P0 objects
awk -F, '$6 ~ /P0/ {printf "%-12s %-35s -> %-35s\n", $1, $2, $3}' docs/naming-conversion-map.csv
```

**Output:**
```
function     McGetDownStream                     -> mcgetdownstream
function     McGetDownStreamByList               -> mcgetdownstreambylist
function     McGetUpStream                       -> mcgetupstream
function     McGetUpStreamByList                 -> mcgetupstreambylist
procedure    AddArc                              -> addarc
procedure    ReconcileMUpstream                  -> reconcile_mupstream
procedure    RemoveArc                           -> removearc
table        goo                                 -> goo
table        m_downstream                        -> m_downstream
table        m_upstream                          -> m_upstream
type         GooList                             -> tmp_goo_list
view         translated                          -> translated
```

### List Completed vs Pending

```bash
# Completed objects (ready to use)
awk -F, '$8=="COMPLETE" {printf "%-12s %-35s\n", $1, $2}' docs/naming-conversion-map.csv

# Pending objects (not yet migrated)
awk -F, '$8=="PENDING" {printf "%-12s %-35s (Priority: %s)\n", $1, $2, $6}' docs/naming-conversion-map.csv
```

---

## 🧪 Testing Checklist

### For Each Query/Procedure Call:

1. **Identify all database objects** in the query
   - Tables, views, functions, procedures
   - Use grep to find each object in naming map

2. **Update names** to PostgreSQL format
   - Apply schema qualification (`perseus.`)
   - Convert to snake_case
   - Handle special cases (Mc prefix, TVP → temp table)

3. **Update parameters** (if applicable)
   - SQL Server: `@paramName`
   - PostgreSQL: `$1, $2, $3` (positional) or `:paramName` (named with driver support)

4. **Test query** in PostgreSQL staging environment
   - Verify results match SQL Server
   - Check performance (within ±20% baseline)

5. **Update application configuration**
   - Connection string: SQL Server → PostgreSQL
   - Port: 1433 → 5432
   - Database name: `perseus` → `perseus_dev` (staging) or `perseus_prod` (production)

---

## 📚 Conversion Rules Summary

### 1. General Pattern
```
PascalCase                    → snake_case
SQL Server: GetMaterialByRunProperties
PostgreSQL: get_material_by_run_properties
```

### 2. Prefix Removal
```
sp_*, usp_* prefixes removed
SQL Server: usp_UpdateMUpstream
PostgreSQL: update_mupstream
```

### 3. Mc Prefix (Special Case)
```
Mc* functions: lowercase, NO underscores
SQL Server: McGetUpStream
PostgreSQL: mcgetupstream
```

### 4. Schema Always Required
```
SQL Server: dbo.TableName
PostgreSQL: perseus.table_name
```

### 5. Case Sensitivity
```
SQL Server: Case-insensitive (SELECT = select = SeLeCt)
PostgreSQL: Case-sensitive (use lowercase)
  ✅ SELECT * FROM perseus.goo;
  ❌ SELECT * FROM perseus.Goo;  -- Error: relation "Goo" does not exist
```

---

## ⚠️ Common Pitfalls

### 1. Forgetting Schema Qualification
```sql
-- ❌ Wrong
SELECT * FROM goo;

-- ✅ Correct
SELECT * FROM perseus.goo;
```

### 2. Using Uppercase Names
```sql
-- ❌ Wrong
SELECT * FROM perseus.Goo;  -- Error: relation "Goo" does not exist

-- ✅ Correct
SELECT * FROM perseus.goo;
```

### 3. Incorrect Mc Prefix Conversion
```sql
-- ❌ Wrong
SELECT * FROM perseus.mc_get_upstream('MAT-123');

-- ✅ Correct
SELECT * FROM perseus.mcgetupstream('MAT-123');
```

### 4. Not Converting TVP to Temporary Table
```sql
-- ❌ Wrong (SQL Server syntax won't work)
DECLARE @materials GooList;

-- ✅ Correct
CREATE TEMPORARY TABLE tmp_goo_list (
    goo_id INTEGER PRIMARY KEY
) ON COMMIT DROP;
```

### 5. Missing Function Parentheses
```sql
-- ❌ Wrong
SELECT * FROM perseus.mcgetupstream;  -- Missing parameter

-- ✅ Correct
SELECT * FROM perseus.mcgetupstream('MAT-123');
```

---

## 📞 Support & Questions

### Documentation References:
- **Naming Map:** `docs/naming-conversion-map.csv`
- **Conversion Rules:** `docs/naming-conversion-rules.md`
- **Project Guide:** `CLAUDE.md`
- **PostgreSQL Constitution:** `docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md`

### Search the Mapping:
```bash
# Find any object by partial name (case-insensitive)
grep -i "material" docs/naming-conversion-map.csv
```

### Python Script for Bulk Conversions:
```bash
python3 scripts/automation/generate-naming-map.py
```

### Contact:
- **Project Lead:** Pierre Ribeiro (Senior DBA/DBRE)
- **Migration Team:** Database migration team
- **Documentation:** See `tracking/activity-log-2026-01.md` for latest updates

---

## 🎓 Learn More

### Full Conversion Rules:
Read `docs/naming-conversion-rules.md` for:
- Detailed conversion algorithms
- Edge cases and exceptions
- Length constraints (63 character limit)
- Reserved word handling
- Test cases and examples

### Migration Project Documentation:
- **CLAUDE.md:** Project overview and standards
- **specs/001-tsql-to-pgsql/spec.md:** Full migration specification
- **dependency-analysis-consolidated.md:** Object dependencies and priorities

---

**Document Version:** 1.0
**Last Updated:** 2026-01-25
**Maintained By:** Perseus Migration Team
