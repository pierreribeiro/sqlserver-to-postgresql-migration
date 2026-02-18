CREATE INDEX ix_recipe_part_ix_recipe_part_goo_type_id
ON perseus_dbo.recipe_part
USING BTREE (goo_type_id ASC)
WITH (FILLFACTOR = 90);

