CREATE INDEX ix_recipe_part_ix_recipe_part_unit_id
ON perseus_dbo.recipe_part
USING BTREE (unit_id ASC)
WITH (FILLFACTOR = 90);

