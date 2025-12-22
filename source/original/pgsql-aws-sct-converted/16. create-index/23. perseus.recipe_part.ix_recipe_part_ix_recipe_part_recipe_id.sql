CREATE INDEX ix_recipe_part_ix_recipe_part_recipe_id
ON perseus_dbo.recipe_part
USING BTREE (recipe_id ASC)
WITH (FILLFACTOR = 90);

