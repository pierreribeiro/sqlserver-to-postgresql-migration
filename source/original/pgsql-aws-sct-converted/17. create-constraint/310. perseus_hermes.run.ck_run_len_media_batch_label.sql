ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_media_batch_label CHECK (length(media_batch_label::text) <= 50);

