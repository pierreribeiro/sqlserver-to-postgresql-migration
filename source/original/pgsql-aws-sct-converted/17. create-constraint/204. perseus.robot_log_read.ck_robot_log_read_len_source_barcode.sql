ALTER TABLE perseus_dbo.robot_log_read
ADD CONSTRAINT ck_robot_log_read_len_source_barcode CHECK (length(source_barcode::text) <= 25);

