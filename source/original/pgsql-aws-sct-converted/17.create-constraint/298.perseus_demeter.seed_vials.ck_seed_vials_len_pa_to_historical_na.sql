ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_pa_to_historical_na CHECK (length(pa_to_historical_na::text) <= 5);

