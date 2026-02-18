CREATE INDEX ix_robot_log_ix_robot_log_robot_run_id
ON perseus_dbo.robot_log
USING BTREE (robot_run_id ASC)
WITH (FILLFACTOR = 90);

