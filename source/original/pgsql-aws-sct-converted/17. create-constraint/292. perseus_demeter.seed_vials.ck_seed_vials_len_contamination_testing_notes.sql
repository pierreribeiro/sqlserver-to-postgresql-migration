ALTER TABLE perseus_demeter.seed_vials
ADD CONSTRAINT ck_seed_vials_len_contamination_testing_notes CHECK (length(contamination_testing_notes::text) <= 250);

