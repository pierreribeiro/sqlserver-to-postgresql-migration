ALTER TABLE perseus_dbo.recipe
ADD CONSTRAINT fk__recipe__feed_typ__471bc4b0 FOREIGN KEY (feed_type_id) 
REFERENCES perseus_dbo.feed_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

