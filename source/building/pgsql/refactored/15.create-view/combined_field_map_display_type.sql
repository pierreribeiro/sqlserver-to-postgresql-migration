-- =============================================================================
-- View: perseus.combined_field_map_display_type
-- Task: T043 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/combined_field_map_display_type-analysis.md
-- Description: Unified field map display type record set — combines the static
--              field_map_display_type base table with synthetic display type entries
--              from combined_sp_field_map_display_type (five UI contexts derived
--              from smurf_property definitions).
-- Dependencies: perseus.field_map_display_type (base table),
--               perseus.combined_sp_field_map_display_type (Wave 0 view)
-- Quality Score: 9.3/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- Column descriptions:
--   id                — Composite ID (base: real; synthetic: sp+10000..50000+dl.id)
--   field_map_id      — Links to combined_field_map
--   display_type_id   — Display type identifier (= dl.id from display_layout)
--   display           — PHP method call string for rendering the value
--   display_layout_id — Layout template (5=edit form, 7=table/list/csv)
--   manditory         — 0 (intentional misspelling preserved from original schema)
--
-- NOTE: The 'manditory' column name is an intentional misspelling of 'mandatory'
--       present in the original SQL Server schema. It MUST be preserved for
--       backward application compatibility. Do NOT correct the spelling.
--
-- Wave: Wave 1
-- Deployment prerequisite: perseus.combined_sp_field_map_display_type (Wave 0) must be deployed first.
-- T-SQL source: dbo.combined_field_map_display_type
-- Issues resolved:
--   P1-01: Wrong schema perseus_dbo -> perseus (all references)
--   P2-01: T-SQL bracket notation removed
--   P2-02: SELECT * in Branch 2 replaced with explicit 6-column list
--   P2-03: 'manditory' misspelling preserved (not a bug — schema compatibility)
--   P2-05: COMMENT ON VIEW added
-- =============================================================================

CREATE OR REPLACE VIEW perseus.combined_field_map_display_type (
    id,
    field_map_id,
    display_type_id,
    display,
    display_layout_id,
    manditory
) AS

-- Branch 1: Real field_map_display_type records from base table
SELECT
    id,
    field_map_id,
    display_type_id,
    display,
    display_layout_id,
    manditory
FROM perseus.field_map_display_type

UNION

-- Branch 2: Synthetic display type records from smurf_property definitions
-- Note: explicit column list replaces SELECT * for resilience to upstream view changes (P2-02)
SELECT
    id,
    field_map_id,
    display_type_id,
    display,
    display_layout_id,
    manditory
FROM perseus.combined_sp_field_map_display_type;

-- Documentation
COMMENT ON VIEW perseus.combined_field_map_display_type IS
    'Unified field map display type registry. Combines static field_map_display_type records '
    'with synthetic entries from combined_sp_field_map_display_type (five smurf_property '
    'display contexts: read edit, read table, listing, CSV, single read edit). '
    'Column ''manditory'' (intentional misspelling) preserved for application compatibility. '
    'Wave 1: requires combined_sp_field_map_display_type (Wave 0) to be deployed first. '
    'Depends on: field_map_display_type (base table), combined_sp_field_map_display_type (view). '
    'T-SQL source: dbo.combined_field_map_display_type | Migration task T043.';

GRANT SELECT ON perseus.combined_field_map_display_type TO perseus_app, perseus_readonly;
