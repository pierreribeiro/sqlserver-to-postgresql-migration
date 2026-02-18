CREATE INDEX ix_goo_ix_goo_recipe_id
ON perseus_dbo.goo
USING BTREE (recipe_id ASC)
WITH (FILLFACTOR = 90);

