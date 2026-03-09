-- =============================================================================
-- View: perseus.combined_sp_field_map_display_type
-- Task: T042 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/combined_sp_field_map_display_type-analysis.md
-- Description: Generates synthetic field_map_display_type records from smurf_property
--              definitions for five display layout contexts.
-- Dependencies: perseus.smurf_property, perseus.smurf, perseus.property,
--               perseus.display_layout
-- Quality Score: 8.6/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- View: perseus.combined_sp_field_map_display_type
-- Description: Generates synthetic field_map_display_type records from
--              smurf_property definitions. Five branches represent different
--              display layout contexts:
--              Branch 1 (id=sp+10000+dl, map=sp+20000, layout=5): Reading edit form
--              Branch 2 (id=sp+20000+dl, map=sp+20000, layout=7): Reading table view
--              Branch 3 (id=sp+30000+dl, map=sp+30000, layout=7): Listing context
--              Branch 4 (id=sp+40000+dl, map=sp+30000, layout=7): CSV context
--              Branch 5 (id=sp+50000+dl, map=sp+40000, layout=5): Single read edit
--
--              NOTE: Column 'manditory' is an intentional misspelling preserved from
--              the T-SQL original for application backward compatibility.
--
--              PREREQUISITE: display_layout must contain rows for id IN (1, 3, 6, 7).
--
-- Depends on:  perseus.smurf_property (base table)
--              perseus.smurf (base table)
--              perseus.property (base table)
--              perseus.display_layout (base table)
-- Blocks:      perseus.combined_field_map_display_type (Wave 1)
-- Wave:        Wave 0
-- T-SQL ref:   dbo.combined_sp_field_map_display_type
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.combined_sp_field_map_display_type (
    id,
    field_map_id,
    display_type_id,
    display,
    display_layout_id,
    manditory
) AS

-- Branch 1: Fatsmurf reading editing (getPollValue, layout=5, dl.id=1)
SELECT
    sp.id + 10000 + dl.id                                              AS id,
    sp.id + 20000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueBySmurfPropertyId(' || sp.id::TEXT || ')'             AS display,
    5                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (1)

UNION

-- Branch 2: Fatsmurf reading table (getPollValue, layout=7, dl.id=7)
SELECT
    sp.id + 20000 + dl.id                                              AS id,
    sp.id + 20000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueBySmurfPropertyId(' || sp.id::TEXT || ')'             AS display,
    7                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (7)

UNION

-- Branch 3: Fatsmurf listing (getPollValueString, layout=7, dl.id=3)
SELECT
    sp.id + 30000 + dl.id                                              AS id,
    sp.id + 30000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueStringBySmurfPropertyId(' || sp.id::TEXT || ')'       AS display,
    7                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (3)

UNION

-- Branch 4: Fatsmurf CSV (getPollValueString, layout=7, dl.id=6, field_map_id=sp+30000)
SELECT
    sp.id + 40000 + dl.id                                              AS id,
    sp.id + 30000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueStringBySmurfPropertyId(' || sp.id::TEXT || ')'       AS display,
    7                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (6)

UNION

-- Branch 5: Fatsmurf single reading editing (getPollValue, layout=5, dl.id=1, field_map_id=sp+40000)
SELECT
    sp.id + 50000 + dl.id                                              AS id,
    sp.id + 40000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueBySmurfPropertyId(' || sp.id::TEXT || ')'             AS display,
    5                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (1);

-- Documentation
COMMENT ON VIEW perseus.combined_sp_field_map_display_type IS
    'Generates synthetic field_map_display_type rows for 5 smurf_property display contexts. '
    'Uses CROSS JOIN to display_layout filtered by dl.id to derive composite id values. '
    'Column ''manditory'' (intentional misspelling) preserved for application compatibility. '
    'Prerequisite: display_layout must contain id IN (1, 3, 6, 7). '
    'Combined with field_map_display_type base table in combined_field_map_display_type (Wave 1). '
    'Depends on: smurf_property, smurf, property, display_layout. '
    'T-SQL source: dbo.combined_sp_field_map_display_type | Migration task T038.';

GRANT SELECT ON perseus.combined_sp_field_map_display_type TO perseus_app, perseus_readonly;
