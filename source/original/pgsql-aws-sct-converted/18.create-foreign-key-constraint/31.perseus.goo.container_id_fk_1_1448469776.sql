ALTER TABLE perseus_dbo.goo
ADD CONSTRAINT container_id_fk_1_1448469776 FOREIGN KEY (container_id) 
REFERENCES perseus_dbo.container (id)
ON UPDATE NO ACTION
ON DELETE SET NULL;

