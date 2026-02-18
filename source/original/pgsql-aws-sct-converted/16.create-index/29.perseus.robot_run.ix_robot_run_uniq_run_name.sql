CREATE UNIQUE INDEX ix_robot_run_uniq_run_name
ON perseus_dbo.robot_run
USING BTREE (name ASC)
WITH (FILLFACTOR = 70);

