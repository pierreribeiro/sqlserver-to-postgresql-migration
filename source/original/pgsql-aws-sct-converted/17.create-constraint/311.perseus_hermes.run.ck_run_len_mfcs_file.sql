ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_mfcs_file CHECK (length(mfcs_file::text) <= 250);

