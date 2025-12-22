ALTER TABLE perseus_dbo.robot_log_transfer
ADD CONSTRAINT ck_robot_log_transfer_len_transfer_volume CHECK (length(transfer_volume::text) <= 25);

