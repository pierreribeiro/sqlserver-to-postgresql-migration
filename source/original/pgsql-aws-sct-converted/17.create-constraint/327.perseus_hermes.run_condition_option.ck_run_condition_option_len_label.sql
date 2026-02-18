ALTER TABLE perseus_hermes.run_condition_option
ADD CONSTRAINT ck_run_condition_option_len_label CHECK (length(label::text) <= 500);

