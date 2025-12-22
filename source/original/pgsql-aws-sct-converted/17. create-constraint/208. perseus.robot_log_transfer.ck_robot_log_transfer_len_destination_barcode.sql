ALTER TABLE perseus_dbo.robot_log_transfer
ADD CONSTRAINT ck_robot_log_transfer_len_destination_barcode CHECK (length(destination_barcode::text) <= 25);

