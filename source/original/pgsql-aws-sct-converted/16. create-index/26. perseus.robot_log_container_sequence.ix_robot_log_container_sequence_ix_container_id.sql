CREATE INDEX ix_robot_log_container_sequence_ix_container_id
ON perseus_dbo.robot_log_container_sequence
USING BTREE (container_id ASC)
WITH (FILLFACTOR = 100);

