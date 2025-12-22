ALTER TABLE perseus_dbo.transition_material
ADD CONSTRAINT ck_transition_material_len_material_id CHECK (length(material_id::text) <= 50);

