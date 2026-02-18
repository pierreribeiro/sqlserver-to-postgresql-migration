CREATE TRIGGER validatetransitionmaterial
AFTER INSERT
ON perseus_dbo.transition_material
REFERENCING NEW TABLE AS inserted
FOR EACH STATEMENT EXECUTE PROCEDURE perseus_dbo.fn_validatetransitionmaterial();

