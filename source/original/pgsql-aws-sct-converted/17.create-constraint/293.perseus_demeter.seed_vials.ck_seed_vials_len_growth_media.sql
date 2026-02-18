ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_growth_media CHECK (length(growth_media::text) <= 50);

