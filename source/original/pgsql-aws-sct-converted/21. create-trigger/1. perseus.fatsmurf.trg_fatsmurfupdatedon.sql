CREATE TRIGGER trg_fatsmurfupdatedon
AFTER UPDATE
ON perseus_dbo.fatsmurf
REFERENCING OLD TABLE AS deleted NEW TABLE AS inserted
FOR EACH STATEMENT EXECUTE PROCEDURE perseus_dbo.fn_trg_fatsmurfupdatedon();

