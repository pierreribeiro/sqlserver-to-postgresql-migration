ALTER TABLE perseus_dbo.feed_type
ADD CONSTRAINT fk__feed_type__creat__5f28586b FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

