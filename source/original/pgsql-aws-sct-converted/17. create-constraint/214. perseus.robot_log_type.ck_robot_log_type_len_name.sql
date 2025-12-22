ALTER TABLE perseus_dbo.robot_log_type
ADD CONSTRAINT ck_robot_log_type_len_name CHECK (length(name::text) <= 150);

