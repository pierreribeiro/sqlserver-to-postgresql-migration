CREATE TRIGGER updateworkflowstepdepth_after_insert
AFTER INSERT
ON perseus_dbo.workflow_step
REFERENCING NEW TABLE AS inserted$ad6a1e78
FOR EACH STATEMENT EXECUTE PROCEDURE perseus_dbo.fn_updateworkflowstepdepth();

