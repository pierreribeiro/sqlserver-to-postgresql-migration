ALTER TABLE perseus_dbo.material_transition
ADD CONSTRAINT ck_material_transition_len_material_id CHECK (length(material_id::text) <= 50);

