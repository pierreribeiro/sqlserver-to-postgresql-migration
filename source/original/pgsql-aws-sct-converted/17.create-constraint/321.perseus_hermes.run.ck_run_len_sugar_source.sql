ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_sugar_source CHECK (length(sugar_source::text) <= 10);

