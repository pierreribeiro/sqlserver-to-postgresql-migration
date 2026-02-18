CREATE TRIGGER updateworkflowstepdepth_after_update
AFTER UPDATE
ON perseus_dbo.workflow_step
REFERENCING OLD TABLE AS deleted$ad6a1e78 NEW TABLE AS inserted$ad6a1e78
FOR EACH STATEMENT EXECUTE PROCEDURE perseus_dbo.fn_updateworkflowstepdepth();

