ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_overlay_batch_label CHECK (length(overlay_batch_label::text) <= 50);

