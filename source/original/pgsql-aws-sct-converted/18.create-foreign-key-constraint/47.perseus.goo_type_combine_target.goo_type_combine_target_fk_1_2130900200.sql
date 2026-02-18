ALTER TABLE perseus_dbo.goo_type_combine_target
ADD CONSTRAINT goo_type_combine_target_fk_1_2130900200 FOREIGN KEY (goo_type_id) 
REFERENCES perseus_dbo.goo_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

