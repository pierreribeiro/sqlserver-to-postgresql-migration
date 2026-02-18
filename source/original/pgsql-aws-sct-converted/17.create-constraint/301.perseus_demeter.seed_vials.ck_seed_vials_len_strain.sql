ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_strain CHECK (length(strain::text) <= 30);

