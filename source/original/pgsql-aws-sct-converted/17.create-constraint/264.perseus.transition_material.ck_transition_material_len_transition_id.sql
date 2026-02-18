ALTER TABLE perseus_dbo.transition_material
ADD CONSTRAINT ck_transition_material_len_transition_id CHECK (length(transition_id::text) <= 50);

