ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_feedstock_material CHECK (length(feedstock_material::text) <= 50);

