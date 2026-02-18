ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_nat_plating_48hr_od CHECK (length(nat_plating_48hr_od::text) <= 10);

