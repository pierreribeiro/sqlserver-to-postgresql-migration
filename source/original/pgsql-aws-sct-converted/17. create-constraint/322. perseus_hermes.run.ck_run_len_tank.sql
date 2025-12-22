ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_tank CHECK (length(tank::text) <= 20);

