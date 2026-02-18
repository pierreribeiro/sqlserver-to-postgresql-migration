ALTER TABLE perseus_dbo.robot_log_transfer
ADD CONSTRAINT ck_robot_log_transfer_len_source_position CHECK (length(source_position::text) <= 150);

