ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_second_feedstock_material_barcode CHECK (length(second_feedstock_material_barcode::text) <= 50);

