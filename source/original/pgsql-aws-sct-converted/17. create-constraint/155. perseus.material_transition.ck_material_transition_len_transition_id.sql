ALTER TABLE perseus_dbo.material_transition
ADD CONSTRAINT ck_material_transition_len_transition_id CHECK (length(transition_id::text) <= 50);

