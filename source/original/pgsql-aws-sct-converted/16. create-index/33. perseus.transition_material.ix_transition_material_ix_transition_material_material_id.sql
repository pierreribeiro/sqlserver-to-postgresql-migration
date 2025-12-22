CREATE INDEX ix_transition_material_ix_transition_material_material_id
ON perseus_dbo.transition_material
USING BTREE (material_id ASC);

