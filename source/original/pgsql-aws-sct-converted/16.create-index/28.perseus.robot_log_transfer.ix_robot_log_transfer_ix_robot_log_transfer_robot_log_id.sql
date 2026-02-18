CREATE INDEX ix_robot_log_transfer_ix_robot_log_transfer_robot_log_id
ON perseus_dbo.robot_log_transfer
USING BTREE (robot_log_id ASC)
WITH (FILLFACTOR = 90);

