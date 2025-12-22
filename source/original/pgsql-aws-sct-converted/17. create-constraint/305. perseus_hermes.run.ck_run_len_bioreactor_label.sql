ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_bioreactor_label CHECK (length(bioreactor_label::text) <= 30);

