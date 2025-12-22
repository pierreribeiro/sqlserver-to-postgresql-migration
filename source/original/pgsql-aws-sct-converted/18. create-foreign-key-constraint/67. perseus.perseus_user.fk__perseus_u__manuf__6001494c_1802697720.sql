ALTER TABLE perseus_dbo.perseus_user
ADD CONSTRAINT fk__perseus_u__manuf__6001494c_1802697720 FOREIGN KEY (manufacturer_id) 
REFERENCES perseus_dbo.manufacturer (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

