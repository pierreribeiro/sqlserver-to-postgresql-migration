CREATE INDEX ix_recipe_ix_recipe_goo_type_id
ON perseus_dbo.recipe
USING BTREE (goo_type_id ASC)
WITH (FILLFACTOR = 90);

