-- =============================================================================
-- View: perseus.combined_sp_field_map
-- Task: T042 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/combined_sp_field_map-analysis.md
-- Description: Generates synthetic field_map records from smurf_property definitions
--              for three UI rendering contexts (reading edit, list/CSV, single read edit).
-- Dependencies: perseus.smurf_property, perseus.smurf, perseus.property,
--               perseus.unit, perseus.property_option
-- Quality Score: 8.7/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- View: perseus.combined_sp_field_map
-- Description: Generates synthetic field_map records from smurf_property definitions.
--              Three branches represent different UI rendering contexts:
--              Branch 1 (id+20000, block+1000): Fatsmurf reading edit form (setter=set)
--              Branch 2 (id+30000, block+2000): Fatsmurf list/CSV (no setter, save_seq=2)
--              Branch 3 (id+40000, block+3000): Fatsmurf single reading edit (setter=set)
--              Combined with field_map base table in perseus.combined_field_map (Wave 1).
--
-- Depends on:  perseus.smurf_property (base table)
--              perseus.smurf (base table)
--              perseus.property (base table)
--              perseus.unit (base table)
--              perseus.property_option (base table)
-- Blocks:      perseus.combined_field_map (Wave 1)
-- Wave:        Wave 0
-- T-SQL ref:   dbo.combined_sp_field_map
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.combined_sp_field_map (
    id,
    field_map_block_id,
    name,
    description,
    display_order,
    setter,
    lookup,
    lookup_service,
    nullable,
    field_map_type_id,
    database_id,
    save_sequence,
    onchange,
    field_map_set_id
) AS

-- Branch 1: Fatsmurf reading editing (editable poll values, detail form)
SELECT
    sp.id + 20000                                                      AS id,
    sp.smurf_id + 1000                                                 AS field_map_block_id,
    p.name || CASE WHEN u.name IS NOT NULL
                   THEN ' (' || u.name || ')'
                   ELSE ''
              END                                                       AS name,
    NULL::TEXT                                                         AS description,
    sp.sort_order                                                      AS display_order,
    'setPollValueBySpid(' || sp.id::TEXT || ', ?)'                    AS setter,
    CASE WHEN po.property_id IS NULL THEN NULL
         ELSE 'PropertyPeer::getLookupByPropertyId('
              || po.property_id::TEXT || ')'
    END                                                                AS lookup,
    NULL::TEXT                                                         AS lookup_service,
    1                                                                  AS nullable,
    CASE WHEN po.property_id IS NOT NULL THEN 12 ELSE 10 END          AS field_map_type_id,
    NULL::TEXT                                                         AS database_id,
    1                                                                  AS save_sequence,
    NULL::TEXT                                                         AS onchange,
    CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END                      AS field_map_set_id
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON sp.smurf_id = s.id
JOIN perseus.property AS p
    ON sp.property_id = p.id
LEFT JOIN perseus.unit AS u
    ON u.id = p.unit_id
LEFT JOIN perseus.property_option AS po
    ON po.property_id = p.id

UNION

-- Branch 2: Fatsmurf list and CSV (read-only display contexts)
SELECT
    sp.id + 30000                                                      AS id,
    sp.smurf_id + 2000                                                 AS field_map_block_id,
    p.name || CASE WHEN u.name IS NOT NULL
                   THEN ' (' || u.name || ')'
                   ELSE ''
              END                                                       AS name,
    NULL::TEXT                                                         AS description,
    sp.sort_order                                                      AS display_order,
    NULL                                                               AS setter,
    NULL                                                               AS lookup,
    NULL::TEXT                                                         AS lookup_service,
    1                                                                  AS nullable,
    CASE WHEN po.property_id IS NOT NULL THEN 12 ELSE 10 END          AS field_map_type_id,
    NULL::TEXT                                                         AS database_id,
    2                                                                  AS save_sequence,
    NULL::TEXT                                                         AS onchange,
    CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END                      AS field_map_set_id
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON sp.smurf_id = s.id
JOIN perseus.property AS p
    ON sp.property_id = p.id
LEFT JOIN perseus.unit AS u
    ON u.id = p.unit_id
LEFT JOIN perseus.property_option AS po
    ON po.property_id = p.id

UNION

-- Branch 3: Fatsmurf single reading editing (editable, individual read form)
SELECT
    sp.id + 40000                                                      AS id,
    sp.smurf_id + 3000                                                 AS field_map_block_id,
    p.name || CASE WHEN u.name IS NOT NULL
                   THEN ' (' || u.name || ')'
                   ELSE ''
              END                                                       AS name,
    NULL::TEXT                                                         AS description,
    sp.sort_order                                                      AS display_order,
    'setPollValueBySpid(' || sp.id::TEXT || ', ?)'                    AS setter,
    CASE WHEN po.property_id IS NULL THEN NULL
         ELSE 'PropertyPeer::getLookupByPropertyId('
              || po.property_id::TEXT || ')'
    END                                                                AS lookup,
    NULL::TEXT                                                         AS lookup_service,
    1                                                                  AS nullable,
    CASE WHEN po.property_id IS NOT NULL THEN 12 ELSE 10 END          AS field_map_type_id,
    NULL::TEXT                                                         AS database_id,
    2                                                                  AS save_sequence,
    NULL::TEXT                                                         AS onchange,
    CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END                      AS field_map_set_id
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON sp.smurf_id = s.id
JOIN perseus.property AS p
    ON sp.property_id = p.id
LEFT JOIN perseus.unit AS u
    ON u.id = p.unit_id
LEFT JOIN perseus.property_option AS po
    ON po.property_id = p.id;

-- Documentation
COMMENT ON VIEW perseus.combined_sp_field_map IS
    'Generates synthetic field_map rows from smurf_property for three UI contexts: '
    '(1) reading edit forms (id+20000, save_seq=1 with setter), '
    '(2) list/CSV views (id+30000, save_seq=2, no setter), '
    '(3) single reading edit forms (id+40000, save_seq=2 with setter). '
    'Combined with field_map base table in combined_field_map (Wave 1). '
    'Depends on: smurf_property, smurf, property, unit, property_option. '
    'T-SQL source: dbo.combined_sp_field_map | Migration task T038.';

GRANT SELECT ON perseus.combined_sp_field_map TO perseus_app, perseus_readonly;
