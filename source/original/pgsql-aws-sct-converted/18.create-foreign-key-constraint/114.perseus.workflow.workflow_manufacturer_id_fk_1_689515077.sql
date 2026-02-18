ALTER TABLE perseus_dbo.workflow
ADD CONSTRAINT workflow_manufacturer_id_fk_1_689515077 FOREIGN KEY (manufacturer_id) 
REFERENCES perseus_dbo.manufacturer (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

