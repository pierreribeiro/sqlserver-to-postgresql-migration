ALTER TABLE perseus_dbo.perseus_user
ADD CONSTRAINT fk__perseus_u__manuf__5b3c942f_1770697606 FOREIGN KEY (manufacturer_id) 
REFERENCES perseus_dbo.manufacturer (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

