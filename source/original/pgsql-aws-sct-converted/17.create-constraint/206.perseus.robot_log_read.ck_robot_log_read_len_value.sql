ALTER TABLE perseus_dbo.robot_log_read
ADD CONSTRAINT ck_robot_log_read_len_value CHECK (length(value::text) <= 25);

