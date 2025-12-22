ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_second_feedstock_material CHECK (length(second_feedstock_material::text) <= 50);

