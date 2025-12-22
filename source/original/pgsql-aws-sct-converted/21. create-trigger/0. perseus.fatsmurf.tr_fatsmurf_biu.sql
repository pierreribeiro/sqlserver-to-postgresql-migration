CREATE TRIGGER tr_fatsmurf_biu
BEFORE INSERT OR UPDATE
ON perseus_dbo.fatsmurf
FOR EACH ROW
EXECUTE PROCEDURE perseus_dbo.fn_tr_fatsmurf_biu();

