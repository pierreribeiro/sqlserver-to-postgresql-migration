ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_jet_to_historical_na CHECK (length(jet_to_historical_na::text) <= 5);

