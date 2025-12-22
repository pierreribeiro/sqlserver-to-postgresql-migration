ALTER TABLE perseus_hermes.run_master_condition
ADD CONSTRAINT ck_run_master_condition_len_description CHECK (length(description::text) <= 250);

