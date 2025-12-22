ALTER TABLE perseus_dbo.goo_type_combine_component
ADD CONSTRAINT goo_type_combine_component_fk_2_1922899459 FOREIGN KEY (goo_type_combine_target_id) 
REFERENCES perseus_dbo.goo_type_combine_target (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

