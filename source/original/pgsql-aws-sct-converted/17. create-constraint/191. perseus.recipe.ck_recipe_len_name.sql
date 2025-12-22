ALTER TABLE perseus_dbo.recipe
ADD CONSTRAINT ck_recipe_len_name CHECK (length(name::text) <= 200);

