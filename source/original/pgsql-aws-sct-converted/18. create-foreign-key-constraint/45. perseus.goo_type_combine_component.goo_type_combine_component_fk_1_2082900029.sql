ALTER TABLE perseus_dbo.goo_type_combine_component
ADD CONSTRAINT goo_type_combine_component_fk_1_2082900029 FOREIGN KEY (goo_type_id) 
REFERENCES perseus_dbo.goo_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

