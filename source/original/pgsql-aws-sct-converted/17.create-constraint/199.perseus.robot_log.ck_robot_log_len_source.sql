ALTER TABLE perseus_dbo.robot_log
ADD CONSTRAINT ck_robot_log_len_source CHECK (length(source::text) <= 250);

