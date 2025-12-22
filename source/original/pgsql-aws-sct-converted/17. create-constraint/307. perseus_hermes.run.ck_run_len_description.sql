ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_description CHECK (length(description::text) <= 255);

