CREATE OR REPLACE  VIEW perseus_dbo.vw_processable_logs (id, class_id, source, created_on, log_text, file_name, robot_log_checksum, started_on, completed_on, loaded_on, loaded, loadable, robot_run_id, robot_log_type_id) AS
SELECT
    rl.*
    FROM perseus_dbo.robot_log AS rl
    JOIN perseus_dbo.robot_log_type AS rlt
        ON rlt.id = rl.robot_log_type_id
    WHERE COALESCE(rl.loaded, 0) = 0 AND NOT EXISTS (SELECT
        *
        FROM perseus_dbo.robot_log_error AS rle
        JOIN perseus_dbo.robot_log AS rl_c
            ON rle.robot_log_id = rl_c.id
        WHERE rle.robot_log_id = rl_c.id AND rl_c.robot_run_id = rl.robot_run_id) AND rl.id IN (SELECT
        MIN(id)
        FROM perseus_dbo.robot_log AS rl_d
        GROUP BY robot_log_checksum) AND (EXISTS (SELECT
        *
        FROM perseus_dbo.robot_log_read AS rlr
        WHERE rlr.robot_log_id = rl.id) OR EXISTS (SELECT
        *
        FROM perseus_dbo.robot_log_transfer AS rlt
        WHERE rlt.robot_log_id = rl.id)) AND COALESCE(rl.loadable, 0) = 1 AND rl.created_on > clock_timestamp() + (- 1::NUMERIC || ' MONTH')::INTERVAL;

