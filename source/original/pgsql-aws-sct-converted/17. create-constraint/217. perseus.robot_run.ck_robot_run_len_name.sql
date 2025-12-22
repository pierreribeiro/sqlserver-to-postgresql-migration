ALTER TABLE perseus_dbo.robot_run
ADD CONSTRAINT ck_robot_run_len_name CHECK (length(name::text) <= 100);

