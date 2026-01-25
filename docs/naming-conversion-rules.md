# Naming Conversion Rules - SQL Server to PostgreSQL
## Perseus Database Migration

**Document Version:** 1.0
**Created:** 2026-01-25
**Project:** Perseus Database Migration - SQL Server → PostgreSQL 17

---

## Overview

This document defines the systematic naming conventions for converting SQL Server PascalCase names to PostgreSQL snake_case names for all 769 database objects.

---

## Core Conversion Rules

### 1. General PascalCase → snake_case

**Rule:** Insert underscore before uppercase letters (except first), convert to lowercase.

**Examples:**
```
AddArc                      → addarc
RemoveArc                   → removearc
GetMaterialByRunProperties  → get_material_by_run_properties
ProcessSomeMUpstream        → process_some_mupstream
```

**Algorithm:**
1. Scan string left to right
2. Before each uppercase letter (except position 0):
   - If previous character is lowercase → insert underscore
   - If next character is lowercase → insert underscore
3. Convert all to lowercase
4. Remove duplicate underscores

---

### 2. Prefix Removal

**Remove SQL Server prefixes:**
- `sp_` → Stored procedure prefix
- `usp_` → User stored procedure prefix
- `fn_` → Function prefix
- `vw_` → View prefix
- `ix_` → Index prefix
- `pk_` → Primary key prefix
- `fk_` → Foreign key prefix
- `uk_` → Unique key prefix
- `ck_` → Check constraint prefix

**Examples:**
```
sp_MoveNode                 → move_node
usp_UpdateMUpstream         → update_mupstream
vw_lot                      → vw_lot (keep vw_ for views if semantic)
```

**Exception:** Keep `vw_` prefix if it provides semantic value (e.g., distinguishes view from table).

---

### 3. Special Case: Mc Prefix

**Rule:** "Mc" prefix is treated as single unit (not "M" + "c").

**Examples:**
```
McGetUpStream               → mcgetupstream
McGetDownStream             → mcgetdownstream
McGetUpStreamByList         → mcgetupstreambylist
```

**Rationale:** "Mc" is part of the function family name (material-centric operations).

---

### 4. Acronyms & Consecutive Uppercase

**Rule:** Consecutive uppercase letters are kept together, with underscore before transition to lowercase.

**Examples:**
```
GetUpStreamByID             → get_upstream_by_id
ProcessHTTPRequest          → process_http_request
XMLParser                   → xml_parser
```

**Algorithm:**
1. If 2+ consecutive uppercase → keep together
2. Insert underscore before last uppercase if followed by lowercase

---

### 5. Object Type-Specific Rules

#### Procedures
- Remove `sp_` or `usp_` prefix
- Convert to snake_case
- Verb-noun pattern preferred

```
AddArc                      → addarc
sp_MoveNode                 → move_node
usp_UpdateContainerType     → update_container_type
```

#### Functions
- Remove `fn_` prefix if present
- Remove `udf_` prefix if present
- Convert to snake_case
- Use PostgreSQL built-ins where possible

```
GetUpStream                 → getupstream
udf_datetrunc               → datetrunc (→ use date_trunc() built-in)
initCaps                    → initcaps (→ use initcap() built-in)
```

#### Views
- Keep `vw_` prefix for business views (semantic value)
- Remove for system views
- Convert remainder to snake_case

```
translated                  → translated (no prefix)
vw_lot                      → vw_lot (keep prefix)
vw_material_transition_material_up → vw_material_transition_material_up
```

#### Tables
- Convert to snake_case
- Use plural nouns where appropriate
- No prefixes

```
MaterialTransition          → material_transition
TransitionMaterial          → transition_material
GooType                     → goo_type
```

#### Indexes
- Pattern: `ix_<table>_<columns>`
- Convert to snake_case

```
ix_MaterialTransition_TransitionID → ix_material_transition_transition_id
```

#### Constraints
- Primary key: `pk_<table>`
- Foreign key: `fk_<table>_<ref_table>`
- Unique: `uk_<table>_<columns>`
- Check: `ck_<table>_<condition>`

```
PK_Goo                      → pk_goo
FK_MaterialTransition_Goo   → fk_material_transition_goo
UK_Goo_UID                  → uk_goo_uid
CK_Goo_Status               → ck_goo_status
```

#### Types
- User-defined types → TEMPORARY TABLE pattern
- Prefix with `tmp_`

```
GooList                     → tmp_goo_list (TVP → TEMP TABLE)
```

---

## Schema Mapping

### SQL Server → PostgreSQL Schema

**Default Mapping:**
```
dbo                         → perseus
```

**Exceptions:**
```
hermes                      → hermes (preserve cross-schema references)
sqlapps                     → sqlapps (FDW)
deimeter                    → deimeter (FDW)
```

**Qualification:**
- ALL object references MUST be schema-qualified
- Example: `perseus.goo`, `hermes.run`

---

## Length Constraints

**PostgreSQL Identifier Limit:** 63 characters

**Truncation Strategy:**
1. Check if name exceeds 63 characters
2. Abbreviate longest words (e.g., material → mat, transition → trans)
3. Remove vowels from middle words
4. Ensure uniqueness (add numeric suffix if needed)

**Example:**
```
vw_tom_perseus_sample_prep_materials (36 chars) → OK
get_very_long_descriptive_function_name_with_many_parameters (61 chars) → OK
extremely_long_function_name_that_exceeds_postgresql_limits_significantly (73 chars)
  → extremely_long_function_name_that_exceeds_pg_limits_sig (57 chars)
```

---

## Naming Patterns by Object Type

### Tables
- Plural nouns: `customers`, `order_items`
- Descriptive: `material_transition`, `transition_material`
- No abbreviations unless standard (e.g., `id`, `uid`)

### Views
- Optional `v_` prefix: `v_active_customers`
- Or descriptive without prefix: `upstream`, `downstream`
- Materialized views: No special prefix (same as tables)

### Functions/Procedures
- Verb-noun pattern: `get_customer`, `process_order`, `calculate_total`
- Batch operations: `*_by_list` suffix
- Utility functions: Descriptive verb

### Temporary Tables
- Prefix: `tmp_` → `tmp_processing_batch`, `tmp_goo_list`
- Suffix: `_temp` → `processing_temp` (alternative)

### Variables (in PL/pgSQL)
- Prefix: `v_` → `v_count`, `v_total`
- Or suffix: `_` → `customer_id_`, `order_date_` (parameters)

---

## Special Cases & Exceptions

### 1. Preserve Existing PostgreSQL Names
If object already exists in PostgreSQL with different name, use existing.

### 2. Reserved Words
If PostgreSQL reserved word, add underscore suffix: `user_`, `group_`

### 3. Business-Specific Terms
Preserve domain-specific terms:
- `goo` → `goo` (not `material`)
- `fatsmurf` → `fatsmurf` (not `experiment`)
- `hermes` → `hermes` (system name)

### 4. Acronyms
Standard acronyms remain uppercase in context:
- `UID` → `uid`
- `ID` → `id`
- `HTTP` → `http`
- `API` → `api`

---

## Validation Rules

### Automated Checks (T013 - Syntax Validation Script)

1. **No unqualified references:** All objects must include schema
2. **Max 63 characters:** Identifier length check
3. **Valid characters:** `[a-z0-9_]` only
4. **No reserved words:** Check against PostgreSQL reserved word list
5. **Uniqueness:** No duplicate names within same schema

### Manual Review

1. **Semantic correctness:** Does name convey meaning?
2. **Consistency:** Follows established patterns?
3. **Searchability:** Easy to grep/find?

---

## Conversion Examples by Priority

### P0 Critical Objects

| SQL Server | PostgreSQL | Type | Notes |
|------------|-----------|------|-------|
| translated | translated | View | MATERIALIZED VIEW |
| GooList | tmp_goo_list | Type | TVP → TEMP TABLE |
| McGetUpStream | mcgetupstream | Function | Lowercase, no underscores |
| AddArc | addarc | Procedure | Simple conversion |
| goo | goo | Table | Preserve domain term |

### P1 High Priority

| SQL Server | PostgreSQL | Type | Notes |
|------------|-----------|------|-------|
| GetMaterialByRunProperties | get_material_by_run_properties | Procedure | Full snake_case |
| ProcessSomeMUpstream | process_some_mupstream | Procedure | Preserve 'm' prefix |
| upstream | upstream | View | Simple name |
| goo_relationship | goo_relationship | View | Already snake_case |

### P2/P3 Medium/Low Priority

| SQL Server | PostgreSQL | Type | Notes |
|------------|-----------|------|-------|
| usp_UpdateMUpstream | update_mupstream | Procedure | Remove usp_ prefix |
| vw_lot | vw_lot | View | Keep vw_ prefix |
| initCaps | initcaps | Function | Use initcap() built-in |

---

## Implementation Checklist

### Phase 1: Automated Conversion
- [ ] Run `generate-naming-map.py` script
- [ ] Generate `docs/naming-conversion-map.csv`
- [ ] Validate all 769 objects mapped

### Phase 2: Manual Review
- [ ] Review P0 objects (9 objects) - 100% accuracy
- [ ] Review P1 objects (18 objects) - Spot check
- [ ] Review P2/P3 objects - Automated validation

### Phase 3: Application Updates
- [ ] Provide mapping table to application team
- [ ] Update connection strings
- [ ] Update query references

---

## References

- **CLAUDE.md:** Project naming conventions
- **Constitution:** Article V - Idiomatic Naming & Scoping
- **PostgreSQL Documentation:** Identifiers and Key Words
- **Dependency Analysis:** Object inventory (lote1-4)

---

## Appendix: Test Cases

### Test Conversions

```python
# Simple PascalCase
assert to_snake_case("AddArc") == "addarc"
assert to_snake_case("RemoveArc") == "removearc"

# With underscores
assert to_snake_case("GetMaterialByRunProperties") == "get_material_by_run_properties"

# Mc prefix
assert to_snake_case("McGetUpStream") == "mcgetupstream"

# Prefix removal
assert to_snake_case("sp_MoveNode") == "move_node"
assert to_snake_case("usp_UpdateMUpstream") == "update_mupstream"

# Consecutive uppercase
assert to_snake_case("GetHTTPResponse") == "get_http_response"
assert to_snake_case("ProcessXMLData") == "process_xml_data"

# Mixed
assert to_snake_case("ProcessSomeMUpstream") == "process_some_mupstream"
```

---

**Document Owner:** Pierre Ribeiro
**Last Updated:** 2026-01-25
**Version:** 1.0
