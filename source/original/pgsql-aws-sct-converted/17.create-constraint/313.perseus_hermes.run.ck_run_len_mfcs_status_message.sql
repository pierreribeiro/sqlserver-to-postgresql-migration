ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_mfcs_status_message CHECK (length(mfcs_status_message::text) <= 400);

