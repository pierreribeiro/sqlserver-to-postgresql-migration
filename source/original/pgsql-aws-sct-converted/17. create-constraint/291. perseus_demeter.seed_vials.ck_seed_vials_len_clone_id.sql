ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_clone_id CHECK (length(clone_id::text) <= 20);

