ALTER TABLE perseus_dbo.feed_type
ADD CONSTRAINT fk__feed_type__updat__601c7ca4 FOREIGN KEY (updated_by_id) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

