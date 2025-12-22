CREATE INDEX ix_robot_log_read_ix_robot_log_read_robot_log_id
ON perseus_dbo.robot_log_read
USING BTREE (robot_log_id ASC)
WITH (FILLFACTOR = 90);

