ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_uv_fene_to_historical_na CHECK (length(uv_fene_to_historical_na::text) <= 5);

