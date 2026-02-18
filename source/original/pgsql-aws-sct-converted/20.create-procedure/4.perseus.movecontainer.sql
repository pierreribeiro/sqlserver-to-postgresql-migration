CREATE OR REPLACE PROCEDURE perseus_dbo.movecontainer(IN "@ChildId" INTEGER, IN "@ParentId" INTEGER)
AS 
$BODY$
DECLARE
    var_myFormerScope CITEXT;
    var_myFormerLeft INTEGER;
    var_myFormerRight INTEGER;
    var_TempScope CITEXT;
    var_myParentScope CITEXT;
    var_myParentLeft INTEGER;
    error_catch$ERROR_NUMBER TEXT;
    error_catch$ERROR_SEVERITY TEXT;
    error_catch$ERROR_STATE TEXT;
    error_catch$ERROR_LINE TEXT;
    error_catch$ERROR_PROCEDURE TEXT;
    error_catch$ERROR_MESSAGE TEXT;
    var_ErrorMessage CITEXT;
    var_ErrorSeverity INTEGER;
BEGIN
    BEGIN
        /* Remove from current location */
        
        /*
        [7811 - Severity CRITICAL - PostgreSQL doesn't support the CONVERT function. DMS SC skips this unsupported function in the converted code. Create a user-defined function to replace the unsupported function.]
        SET @TempScope = LEFT(CONVERT(VARCHAR(150), NEWID()), 32)
        */
        SELECT
            w.scope_id, w.left_id, w.right_id
            INTO var_myFormerScope, var_myFormerLeft, var_myFormerRight
            FROM perseus_dbo.container AS w
            WHERE w.id = "@ChildId";
        UPDATE perseus_dbo.container
        SET scope_id = var_TempScope
            WHERE scope_id = var_myFormerScope AND left_id >= var_myFormerLeft AND right_id <= var_myFormerRight;
        UPDATE perseus_dbo.container
        SET left_id = left_id - (var_myFormerRight - var_myFormerLeft) - 1
            WHERE left_id > var_myFormerRight AND scope_id = var_myFormerScope;
        UPDATE perseus_dbo.container
        SET right_id = right_id - (var_myFormerRight - var_myFormerLeft) - 1
            WHERE right_id > var_myFormerRight AND scope_id = var_myFormerScope;
        /* Add in New Position */
        SELECT
            scope_id, left_id
            INTO var_myParentScope, var_myParentLeft
            FROM perseus_dbo.container
            WHERE id = "@ParentId";
        UPDATE perseus_dbo.container
        SET left_id = left_id + (var_myFormerRight - var_myFormerLeft) + 1
            WHERE left_id > var_myParentLeft AND scope_id = var_myParentScope;
        UPDATE perseus_dbo.container
        SET right_id = right_id + (var_myFormerRight - var_myFormerLeft) + 1
            WHERE right_id > var_myParentLeft AND scope_id = var_myParentScope;
        UPDATE perseus_dbo.container
        SET scope_id = var_myParentScope, left_id = var_myParentLeft + (left_id - var_myFormerLeft) + 1, right_id = var_myParentLeft + (right_id - var_myFormerLeft) + 1
            WHERE scope_id = var_TempScope;
        UPDATE perseus_dbo.container AS rw
        SET depth = d.parent_count
        FROM perseus_dbo.container AS rw_dml
        JOIN (SELECT
            rw.id, COUNT(p_rw.id) AS parent_count
            FROM perseus_dbo.container AS rw
            LEFT OUTER JOIN perseus_dbo.container AS p_rw
                ON rw_dml.scope_id = p_rw.scope_id AND p_rw.left_id < rw_dml.left_id AND p_rw.right_id > rw_dml.right_id
            GROUP BY rw.id) AS d
            ON d.id = rw.id
            WHERE rw_dml.scope_id IN (var_myFormerScope, var_myParentScope) AND rw.CONTAINER_TYPE_ID = rw_dml.CONTAINER_TYPE_ID AND rw.ID = rw_dml.ID;
        EXCEPTION
            WHEN OTHERS THEN
                error_catch$ERROR_NUMBER := '0';
                error_catch$ERROR_SEVERITY := '0';
                error_catch$ERROR_LINE := '0';
                error_catch$ERROR_PROCEDURE := 'MOVECONTAINER';
                GET STACKED DIAGNOSTICS error_catch$ERROR_STATE = RETURNED_SQLSTATE,
                    error_catch$ERROR_MESSAGE = MESSAGE_TEXT;
                /*
                [7922 - Severity LOW - PostgreSQL uses a different approach to handle errors compared to the source code. Review the converted code and change it where necessary.]
                SELECT @ErrorMessage = ERROR_MESSAGE()
                */
                SELECT
                    error_catch$ERROR_MESSAGE
                    INTO var_ErrorMessage;
                RAISE 'Error %, severity %, state % was raised. Message: %. Argument: %. Argument: %. Argument: %', '50000', 16, 1, 'Could not move %d to %d: %s', "@ChildId", "@ParentId", var_ErrorMessage USING ERRCODE = '50000';
                ROLLBACK;
    END;
END;
$BODY$
LANGUAGE plpgsql;

