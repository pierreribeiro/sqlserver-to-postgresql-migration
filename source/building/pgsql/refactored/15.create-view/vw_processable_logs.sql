-- =============================================================================
-- View: perseus.vw_processable_logs
-- Task: T042 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_processable_logs-analysis.md
-- Description: Filters robot_log to rows that are eligible for processing.
--              A log entry is processable if all six conditions are true:
--              1. Not already loaded (loaded IS NULL OR loaded = 0)
--              2. No error log exists for the same robot_run_id
--              3. It is the earliest entry (MIN id) with its checksum
--              4. Has at least one associated read or transfer record
--              5. Explicitly marked loadable (loadable = 1)
--              6. Created within the last calendar month
-- Dependencies: perseus.robot_log (base table), perseus.robot_log_type (base table),
--               perseus.robot_log_error (base table), perseus.robot_log_read (base table),
--               perseus.robot_log_transfer (base table)
-- Quality Score: 8.5/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- NOTE: The JOIN to robot_log_type is preserved from the T-SQL original.
--       Review whether it adds filtering value; if robot_log_type_id has a
--       NOT NULL FK constraint, this JOIN is redundant (see analysis P2-05).
--
-- Key corrections vs AWS SCT output:
--   - Date arithmetic: CURRENT_TIMESTAMP - INTERVAL '1 month'
--     (SCT incorrectly emitted: clock_timestamp() + (- 1::NUMERIC || ' MONTH')::INTERVAL)
--   - Explicit column list replaces rl.*
--   - robot_log_transfer alias renamed from rlt to rltr (rlt already used for robot_log_type)
--   - SELECT 1 used in EXISTS subqueries (idiomatic)
--   - Schema corrected from perseus_dbo to perseus
--
-- Wave:      Wave 0
-- Blocks:    None
-- T-SQL ref: dbo.vw_processable_logs
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_processable_logs (
    id,
    class_id,
    source,
    created_on,
    log_text,
    file_name,
    robot_log_checksum,
    started_on,
    completed_on,
    loaded_on,
    loaded,
    loadable,
    robot_run_id,
    robot_log_type_id
) AS
SELECT
    rl.id,
    rl.class_id,
    rl.source,
    rl.created_on,
    rl.log_text,
    rl.file_name,
    rl.robot_log_checksum,
    rl.started_on,
    rl.completed_on,
    rl.loaded_on,
    rl.loaded,
    rl.loadable,
    rl.robot_run_id,
    rl.robot_log_type_id
FROM perseus.robot_log AS rl
JOIN perseus.robot_log_type AS rlt
    ON rlt.id = rl.robot_log_type_id
WHERE COALESCE(rl.loaded, 0) = 0
  AND NOT EXISTS (
        SELECT 1
        FROM perseus.robot_log_error AS rle
        JOIN perseus.robot_log AS rl_c
            ON rle.robot_log_id = rl_c.id
        WHERE rl_c.robot_run_id = rl.robot_run_id
  )
  AND rl.id IN (
        SELECT MIN(id)
        FROM perseus.robot_log AS rl_d
        GROUP BY robot_log_checksum
  )
  AND (
        EXISTS (
            SELECT 1
            FROM perseus.robot_log_read AS rlr
            WHERE rlr.robot_log_id = rl.id
        )
        OR EXISTS (
            SELECT 1
            FROM perseus.robot_log_transfer AS rltr
            WHERE rltr.robot_log_id = rl.id
        )
  )
  AND COALESCE(rl.loadable, 0) = 1
  AND rl.created_on > CURRENT_TIMESTAMP - INTERVAL '1 month';

-- Documentation
COMMENT ON VIEW perseus.vw_processable_logs IS
    'Filters robot_log to entries eligible for processing. A log is processable '
    'when: not yet loaded, no error for same run, earliest by checksum, has a '
    'read or transfer record, explicitly marked loadable, and created within 1 month. '
    'Key fix: DATEADD(MONTH,-1,GETDATE()) -> CURRENT_TIMESTAMP - INTERVAL ''1 month''. '
    'Alias rlt (robot_log_transfer in EXISTS) renamed to rltr for clarity. '
    'Depends on: robot_log, robot_log_type, robot_log_error, robot_log_read, robot_log_transfer. '
    'T-SQL source: dbo.vw_processable_logs | Migration task T038.';

GRANT SELECT ON perseus.vw_processable_logs TO perseus_app, perseus_readonly;
