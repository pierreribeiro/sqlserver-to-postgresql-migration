ALTER TABLE perseus_dbo.goo_process_queue_type
ADD CONSTRAINT ck_goo_process_queue_type_len_name CHECK (length(name::text) <= 50);

