ALTER TABLE perseus_dbo.recipe
ADD CONSTRAINT ck_recipe_len_sterilization_method CHECK (length(sterilization_method::text) <= 100);

