ALTER TABLE perseus_dbo.robot_log_transfer
ADD CONSTRAINT ck_robot_log_transfer_len_source_barcode CHECK (length(source_barcode::text) <= 25);

