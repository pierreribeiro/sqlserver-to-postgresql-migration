ALTER TABLE perseus_dbo.robot_log_transfer
ADD CONSTRAINT ck_robot_log_transfer_len_destination_position CHECK (length(destination_position::text) <= 150);

