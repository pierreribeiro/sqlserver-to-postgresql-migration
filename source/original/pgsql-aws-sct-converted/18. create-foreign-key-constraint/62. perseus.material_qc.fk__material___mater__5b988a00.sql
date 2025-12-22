ALTER TABLE perseus_dbo.material_qc
ADD CONSTRAINT fk__material___mater__5b988a00 FOREIGN KEY (material_id) 
REFERENCES perseus_dbo.goo (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

