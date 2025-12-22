CREATE TRIGGER trg_gooupdatedon
AFTER UPDATE
ON perseus_dbo.goo
REFERENCING OLD TABLE AS deleted NEW TABLE AS inserted
FOR EACH STATEMENT EXECUTE PROCEDURE perseus_dbo.fn_trg_gooupdatedon();

