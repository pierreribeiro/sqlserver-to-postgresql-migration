ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_mfcs_status CHECK (length(mfcs_status::text) <= 10);

