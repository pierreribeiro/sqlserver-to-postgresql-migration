-- =============================================================================
-- View: perseus.combined_field_map_block
-- Task: T042 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/combined_field_map_block-analysis.md
-- Description: Unified field_map_block record set combining real field_map_block rows
--              with three synthetic block types generated from smurf definitions.
-- Dependencies: perseus.field_map_block, perseus.smurf
-- Quality Score: 9.2/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- View: perseus.combined_field_map_block
-- Description: Unified field_map_block record set combining the base field_map_block
--              table with three synthetic block types generated from smurf definitions.
--              Four branches via UNION:
--              Branch 1: Real field_map_block rows (id, filter, scope as-is)
--              Branch 2 (id+1000): FatSmurfReading blocks — isSmurf(N) filter
--              Branch 3 (id+2000): FatSmurf list/CSV — isSmurf(N) filter
--              Branch 4 (id+3000): Single-reading FatSmurf — isSmurfWithOneReading(N)
--
--              ASSUMPTION: field_map_block.id < 1000 (no ID collision with Branch 2).
--              Verify with: SELECT MAX(id) FROM perseus.field_map_block;
--
-- Depends on:  perseus.field_map_block (base table)
--              perseus.smurf (base table)
-- Blocks:      None
-- Wave:        Wave 0
-- T-SQL ref:   dbo.combined_field_map_block
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.combined_field_map_block (
    id,
    filter,
    scope
) AS

-- Branch 1: Base field_map_block records
SELECT
    id,
    filter,
    scope
FROM perseus.field_map_block

UNION

-- Branch 2: FatSmurf reading blocks (one per smurf)
SELECT
    id + 1000,
    'isSmurf(' || id::TEXT || ')',
    'FatSmurfReading'
FROM perseus.smurf

UNION

-- Branch 3: FatSmurf list and CSV blocks
SELECT
    id + 2000,
    'isSmurf(' || id::TEXT || ')',
    'FatSmurf'
FROM perseus.smurf

UNION

-- Branch 4: Single-reading FatSmurf blocks
SELECT
    id + 3000,
    'isSmurfWithOneReading(' || id::TEXT || ')',
    'FatSmurf'
FROM perseus.smurf;

-- Documentation
COMMENT ON VIEW perseus.combined_field_map_block IS
    'Unified field map block registry. Combines real field_map_block rows with '
    'three synthetic block types derived from smurf definitions. '
    'Synthetic IDs use offsets +1000 (reading), +2000 (list/csv), +3000 (single read) '
    'to avoid collision with base field_map_block IDs (assumed < 1000). '
    'filter and scope columns drive UI context evaluation in the application layer. '
    'Depends on: field_map_block, smurf (base tables). '
    'T-SQL source: dbo.combined_field_map_block | Migration task T038.';

GRANT SELECT ON perseus.combined_field_map_block TO perseus_app, perseus_readonly;
