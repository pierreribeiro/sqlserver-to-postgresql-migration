ALTER TABLE perseus_dbo.robot_log
ADD CONSTRAINT ck_robot_log_len_file_name CHECK (length(file_name::text) <= 250);

