ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_strain CHECK (length(strain::text) <= 30);

