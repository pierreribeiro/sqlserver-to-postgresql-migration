ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT field_map_field_map_set_fk_1_927875664 FOREIGN KEY (field_map_set_id) 
REFERENCES perseus_dbo.field_map_set (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

