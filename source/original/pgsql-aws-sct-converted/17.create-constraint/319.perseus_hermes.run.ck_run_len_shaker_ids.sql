ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_shaker_ids CHECK (length(shaker_ids::text) <= 50);

