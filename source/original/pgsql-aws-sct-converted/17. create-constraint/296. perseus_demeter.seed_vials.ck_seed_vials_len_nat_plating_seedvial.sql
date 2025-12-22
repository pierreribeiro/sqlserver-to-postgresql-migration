ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_nat_plating_seedvial CHECK (length(nat_plating_seedvial::text) <= 10);

