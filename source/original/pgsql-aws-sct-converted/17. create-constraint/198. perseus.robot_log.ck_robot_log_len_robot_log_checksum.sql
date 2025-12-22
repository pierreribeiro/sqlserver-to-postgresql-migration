ALTER TABLE perseus_dbo.robot_log
ADD CONSTRAINT ck_robot_log_len_robot_log_checksum CHECK (length(robot_log_checksum::text) <= 32);

