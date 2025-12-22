ALTER TABLE perseus_hermes.run_master_condition
ADD CONSTRAINT ck_run_master_condition_len_units CHECK (length(units::text) <= 25);

