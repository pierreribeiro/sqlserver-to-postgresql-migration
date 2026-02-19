# US1 — View Migration Sequence (T033)

**Project**: Perseus Database Migration (SQL Server → PostgreSQL 17)
**User Story**: US1 — Critical Views Migration
**Created**: 2026-02-19
**Tasks**: T031 (dependency review) + T032 (table readiness) → T033 (this document)

---

## Summary

| Metric | Value |
|--------|-------|
| Total views | 22 |
| P0 (Critical) | 1 — `translated` |
| P1 (High) | 4 — `upstream`, `downstream`, `goo_relationship`, `hermes_run` |
| P2 (Medium) | 10 |
| P3 (Low) | 7 |
| Local table deps | 24 — all ✅ deployed |
| FDW table deps | 2 (`hermes.run`, `hermes.run_condition_value`) — ⚠️ server connection pending |
| Views blocked by FDW | 3 (`goo_relationship`, `hermes_run`, `vw_jeremy_runs`) |
| Views fully unblocked | 19 |

---

## Deployment Waves

Migration must respect inter-view dependencies. All base tables are deployed. The only external blocker is the `hermes` FDW server connection.

---

### Wave 0 — Base Views (no view dependencies)

These views depend only on base tables and can be created in any order / in parallel.
`translated` MUST be prioritized first (P0 — blocks all P1+ critical views and 4 P0 functions).

| Order | View | PostgreSQL Name | Priority | Complexity | FDW Dep | Notes |
|-------|------|-----------------|----------|------------|---------|-------|
| 1 | `translated` | `translated` | **P0** | 8/10 | No | Indexed view → MATERIALIZED VIEW + UNIQUE INDEX. Blocks upstream, downstream, material_transition_material and all 4 McGet* functions. |
| 2 | `vw_process_upstream` | `vw_process_upstream` | P2 | 5/10 | No | WITH SCHEMABINDING → drop clause. Blocks vw_fermentation_upstream. |
| 3 | `vw_material_transition_material_up` | `vw_material_transition_material_up` | P2 | 3/10 | No | WITH SCHEMABINDING → drop clause. Simple SELECT. |
| 4 | `vw_lot` | `vw_lot` | P2 | 5/10 | No | Blocks vw_lot_edge, vw_lot_path, vw_recipe_prep, vw_recipe_prep_part. |
| 5 | `vw_processable_logs` | `vw_processable_logs` | P2 | 5/10 | No | DATEADD → INTERVAL. ISNULL → COALESCE. |
| 6 | `combined_sp_field_map` | `combined_sp_field_map` | P3 | 5/10 | No | WITH SCHEMABINDING → drop. CONVERT → CAST. Blocks combined_field_map. |
| 7 | `combined_sp_field_map_display_type` | `combined_sp_field_map_display_type` | P3 | 5/10 | No | WITH SCHEMABINDING → drop. Blocks combined_field_map_display_type. |
| 8 | `combined_field_map_block` | `combined_field_map_block` | P3 | 4/10 | No | 4-way UNION. No view deps, no FDW. |
| 9 | `goo_relationship` | `goo_relationship` | P1 | 6/10 | ⚠️ hermes | 3-way UNION. Third branch references hermes.run. Blocks vw_jeremy_runs. Deploy conditionally: first 2 UNION branches only if hermes FDW not ready, or full when FDW is live. |
| 10 | `hermes_run` | `hermes_run` | P1/P2 | 6/10 | ⚠️ hermes | Primary source is hermes.run FDW table. ISNULL → COALESCE. String concat. Deploy only when hermes FDW server is live. |

---

### Wave 1 — Views Depending on Wave 0

These views require at least one Wave 0 view to exist before creation.
Items 11–19 can be created in parallel within Wave 1 (different file targets, no intra-wave dependencies).

| Order | View | PostgreSQL Name | Priority | Complexity | Depends On (View) | Notes |
|-------|------|-----------------|----------|------------|-------------------|-------|
| 11 | `upstream` | `upstream` | P1 | 7/10 | `translated` | Recursive CTE. Path accumulation from translated. Performance risk on large graphs. |
| 12 | `downstream` | `downstream` | P1 | 7/10 | `translated` | Mirror of upstream with inverted traversal. |
| 13 | `material_transition_material` | `material_transition_material` | P2 | 2/10 | `translated` | Thin wrapper SELECT over translated. Trivial conversion. |
| 14 | `vw_fermentation_upstream` | `vw_fermentation_upstream` | P2 | 6/10 | `vw_process_upstream` | Recursive CTE. |
| 15 | `vw_lot_edge` | `vw_lot_edge` | P2 | 4/10 | `vw_lot` | Double self-join on vw_lot (sl, dl aliases). |
| 16 | `vw_lot_path` | `vw_lot_path` | P2 | 3/10 | `vw_lot` | Also requires `m_upstream` table (deployed ✅). Simple join — lower complexity than estimated. |
| 17 | `vw_recipe_prep` | `vw_recipe_prep` | P2 | 3/10 | `vw_lot` | Filter on vw_lot WHERE recipe_id IS NOT NULL. |
| 18 | `combined_field_map` | `combined_field_map` | P3 | 3/10 | `combined_sp_field_map` | UNION with field_map table. |
| 19 | `combined_field_map_display_type` | `combined_field_map_display_type` | P3 | 3/10 | `combined_sp_field_map_display_type` | UNION with field_map_display_type table. |
| 20 | `vw_tom_perseus_sample_prep_materials` | `vw_tom_perseus_sample_prep_materials` | P3 | 3/10 | None (base tables only) | Placed here for scheduling — requires m_downstream table (deployed ✅). Deprecation candidate. |
| 21 | `vw_jeremy_runs` | `vw_jeremy_runs` | P3 | 6/10 | `goo_relationship` | Recursive CTE + hermes FDW + goo nested sets. Most complex P3 view. Deprecation candidate. Deploy only when hermes FDW live AND goo_relationship is deployed. |

---

### Wave 2 — Views Depending on Wave 1

| Order | View | PostgreSQL Name | Priority | Complexity | Depends On (Views) | Notes |
|-------|------|-----------------|----------|------------|---------------------|-------|
| 22 | `vw_recipe_prep_part` | `vw_recipe_prep_part` | P2 | 5/10 | `vw_lot`, `vw_lot_edge` | Requires both Wave 0 (vw_lot) and Wave 1 (vw_lot_edge). |

---

## Dependency Graph

```
Base Tables (all deployed ✅)
│
├── material_transition ──────────────────► translated [P0, MAT VIEW]
│   transition_material                        │
│                                              ├── upstream [P1, Recursive CTE]
│                                              ├── downstream [P1, Recursive CTE]
│                                              └── material_transition_material [P2]
│
├── material_transition ──────────────────► vw_process_upstream [P2]
│   transition_material                        └── vw_fermentation_upstream [P2, Recursive CTE]
│   fatsmurf
│
├── material_transition ──────────────────► vw_material_transition_material_up [P2]
│   transition_material
│
├── goo ─────────────────────────────────► vw_lot [P2]
│   transition_material                        ├── vw_lot_edge [P2]
│   fatsmurf                                   │     └── vw_recipe_prep_part [P2] ◄── vw_lot
│                                              ├── vw_lot_path [P2] (+ m_upstream)
│                                              └── vw_recipe_prep [P2]
│
├── robot_log* ──────────────────────────► vw_processable_logs [P2]
│
├── smurf_property, smurf, ... ──────────► combined_sp_field_map [P3]
│                                              └── combined_field_map [P3] (+ field_map)
│
├── smurf_property, smurf, ... ──────────► combined_sp_field_map_display_type [P3]
│                                              └── combined_field_map_display_type [P3]
│
├── field_map_block, smurf ──────────────► combined_field_map_block [P3]
│
├── goo, fatsmurf ───────────────────────► goo_relationship [P1] ⚠️ FDW(hermes.run)
│   hermes.run (FDW)                           └── vw_jeremy_runs [P3] ⚠️ FDW(hermes.*)
│
├── hermes.run (FDW) ────────────────────► hermes_run [P1/P2] ⚠️ FDW
│   goo, container
│
└── goo, m_downstream ───────────────────► vw_tom_perseus_sample_prep_materials [P3]
```

---

## FDW Blocker — Hermes

Three views depend on the `hermes` FDW server connection being live:

| View | Priority | Impact if FDW not ready |
|------|----------|------------------------|
| `goo_relationship` | P1 | Can deploy with 2 of 3 UNION branches (workaround possible) |
| `hermes_run` | P1/P2 | Cannot deploy at all — entire body queries hermes.run |
| `vw_jeremy_runs` | P3 | Cannot deploy — depends on goo_relationship + hermes.run + hermes.run_condition_value |

**Resolution**: FDW server setup is tracked in `source/building/pgsql/refactored/14.create-table/hermes_fdw_setup.sql`. The `CREATE SERVER` and `CREATE USER MAPPING` statements are commented out pending credentials. This is a P1 issue for the DBA/infra team. Views migration can proceed for 19 unblocked views while FDW is being configured.

---

## Refactoring Notes by View Type

### Indexed View → Materialized View (`translated`)
```sql
-- SQL Server
CREATE VIEW translated WITH SCHEMABINDING AS ...
GO
CREATE UNIQUE CLUSTERED INDEX ix_materialized ON translated(destination_material, source_material, transition_id)

-- PostgreSQL
CREATE MATERIALIZED VIEW translated AS ...
CREATE UNIQUE INDEX ix_translated ON translated(destination_material, source_material, transition_id);
-- + pg_cron refresh schedule (every 10 min, T266)
-- + REFRESH MATERIALIZED VIEW CONCURRENTLY (non-blocking, requires unique index)
```

### WITH SCHEMABINDING → Drop Clause
```sql
-- SQL Server: CREATE VIEW vw_process_upstream WITH SCHEMABINDING AS ...
-- PostgreSQL:  CREATE OR REPLACE VIEW vw_process_upstream AS ...
-- (no SCHEMABINDING equivalent — enforce via deployment procedures)
```

### Common T-SQL → PostgreSQL Transforms (all 22 views)
| T-SQL | PostgreSQL |
|-------|-----------|
| `ISNULL(x, y)` | `COALESCE(x, y)` |
| `CONVERT(VARCHAR(n), x)` | `x::VARCHAR` or `CAST(x AS VARCHAR)` |
| `GETDATE()` | `CURRENT_TIMESTAMP` |
| `DATEADD(MONTH, -1, x)` | `x - INTERVAL '1 month'` |
| `+` (string concat) | `\|\|` or `CONCAT()` |
| `dbo.table_name` | `public.table_name` (schema-qualify all refs) |
| `WITH SCHEMABINDING` | Remove clause |
| `WITH (NOEXPAND)` hint | Remove hint |

---

## Migration Execution Order (Summary)

```
Phase 1 Analysis:   T034 (translated) + T035 (upstream) + T036 (downstream) + T037 (goo_relationship) + T038 (18 others) [P - parallel]
Phase 1 Consolidate: T039

Phase 2 Refactoring:
  T040 translated (P0 materialized view)
  T041 unique index for CONCURRENT refresh
  T042 upstream [P] + T043 downstream [P] + T044 goo_relationship [P] + T045 remaining 18 [P]
  T046 syntax validation

Phase 3 Validation:
  T047-T055 tests + performance + quality gates

Phase 4 Deployment:
  T056 DEV → T057 smoke → T058 STAGING → T059 integration → T060-T062 runbook/approval

Phase 10 (Materialized View Refresh):
  T265 pg_cron install → T266 translated schedule → T267 others → T268-T273 monitoring
```

---

## Output Files (to be created)

Analysis docs → `source/building/pgsql/refactored/15. create-view/`
- `translated-analysis.md` (T034)
- `upstream-analysis.md` (T035)
- `downstream-analysis.md` (T036)
- `goo_relationship-analysis.md` (T037)
- `<name>-analysis.md` × 18 (T038, parallel)

SQL files → `source/building/pgsql/refactored/15. create-view/`
- `translated.sql` (T040 — materialized view)
- `translated-refresh-schedule.sql` (T266)
- `<name>.sql` × 21 remaining views (T041-T045)

Test files → `tests/unit/views/`
- `test_translated.sql` (T047)
- `test_upstream.sql` (T048)
- `test_downstream.sql` (T049)
- `test_<name>.sql` × 19 remaining (T050)

---

*Generated by T033 | Branch: us1-critical-views | 2026-02-19*
