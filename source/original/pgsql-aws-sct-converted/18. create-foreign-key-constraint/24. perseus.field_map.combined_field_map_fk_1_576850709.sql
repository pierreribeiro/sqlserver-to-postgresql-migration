ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT combined_field_map_fk_1_576850709 FOREIGN KEY (field_map_block_id) 
REFERENCES perseus_dbo.field_map_block (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

