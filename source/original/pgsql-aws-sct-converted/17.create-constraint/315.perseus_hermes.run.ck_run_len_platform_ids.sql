ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_platform_ids CHECK (length(platform_ids::text) <= 50);

