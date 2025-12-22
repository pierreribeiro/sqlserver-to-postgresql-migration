ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_productivity_notes CHECK (length(productivity_notes::text) <= 400);

