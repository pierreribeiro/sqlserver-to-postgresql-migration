ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_viability_pre_na CHECK (length(viability_pre_na::text) <= 5);

