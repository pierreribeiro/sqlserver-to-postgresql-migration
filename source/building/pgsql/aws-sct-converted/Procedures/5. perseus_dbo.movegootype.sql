CREATE OR REPLACE PROCEDURE perseus_dbo.movegootype(IN par_childid INTEGER, IN par_parentid INTEGER)
AS 
$BODY$
DECLARE
    var_myFormerScope VARCHAR(50);
    var_myFormerLeft INTEGER;
    var_myFormerRight INTEGER;
    var_TempScope VARCHAR(50);
    var_myParentScope VARCHAR(50);
    var_myParentLeft INTEGER;
    error_catch$ERROR_NUMBER TEXT;
    error_catch$ERROR_SEVERITY TEXT;
    error_catch$ERROR_STATE TEXT;
    error_catch$ERROR_LINE TEXT;
    error_catch$ERROR_PROCEDURE TEXT;
    error_catch$ERROR_MESSAGE TEXT;
    var_ErrorMessage VARCHAR(4000);
    var_ErrorSeverity INTEGER;
BEGIN
    BEGIN
        /* Remove from current location */
        var_TempScope := aws_sqlserver_ext.newid()
        /*
        [7831 - Severity LOW - Make sure that you install the uuid-ossp extension to use the newid() function. Revise your database settings and try again.]
        NEWID()
        */;
        SELECT
            w.scope_id, w.left_id, w.right_id
            INTO var_myFormerScope, var_myFormerLeft, var_myFormerRight
            FROM perseus_dbo.goo_type AS w
            WHERE w.id = par_ChildId;
        UPDATE perseus_dbo.goo_type
        SET scope_id = var_TempScope
            WHERE LOWER(scope_id) = LOWER(var_myFormerScope)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            scope_id = @myFormerScope
            */
            AND left_id >= var_myFormerLeft AND right_id <= var_myFormerRight;
        UPDATE perseus_dbo.goo_type
        SET left_id = left_id - (var_myFormerRight - var_myFormerLeft) - 1
            WHERE left_id > var_myFormerRight AND LOWER(scope_id) = LOWER(var_myFormerScope)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            scope_id = @myFormerScope
            */;
        UPDATE perseus_dbo.goo_type
        SET right_id = right_id - (var_myFormerRight - var_myFormerLeft) - 1
            WHERE right_id > var_myFormerRight AND LOWER(scope_id) = LOWER(var_myFormerScope)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            scope_id = @myFormerScope
            */;
        /* Add in New Position */
        SELECT
            scope_id, left_id
            INTO var_myParentScope, var_myParentLeft
            FROM perseus_dbo.goo_type
            WHERE id = par_ParentId;
        UPDATE perseus_dbo.goo_type
        SET left_id = left_id + (var_myFormerRight - var_myFormerLeft) + 1
            WHERE left_id > var_myParentLeft AND LOWER(scope_id) = LOWER(var_myParentScope)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            scope_id = @myParentScope
            */;
        UPDATE perseus_dbo.goo_type
        SET right_id = right_id + (var_myFormerRight - var_myFormerLeft) + 1
            WHERE right_id > var_myParentLeft AND LOWER(scope_id) = LOWER(var_myParentScope)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            scope_id = @myParentScope
            */;
        UPDATE perseus_dbo.goo_type
        SET scope_id = var_myParentScope, left_id = var_myParentLeft + (left_id - var_myFormerLeft) + 1, right_id = var_myParentLeft + (right_id - var_myFormerLeft) + 1
            WHERE LOWER(scope_id) = LOWER(var_TempScope)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            scope_id = @TempScope
            */;
        UPDATE perseus_dbo.goo_type AS rw
        SET depth = d.parent_count
        FROM perseus_dbo.goo_type AS rw_dml
        JOIN (SELECT
            rw.id, COUNT(p_rw.id) AS parent_count
            FROM perseus_dbo.goo_type AS rw
            LEFT OUTER JOIN perseus_dbo.goo_type AS p_rw
                ON LOWER(rw_dml.scope_id) = LOWER(p_rw.scope_id)
                /*
                [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                rw.scope_id = p_rw.scope_id
                */
                AND p_rw.left_id < rw_dml.left_id AND p_rw.right_id > rw_dml.right_id
            GROUP BY rw.id) AS d
            ON d.id = rw.id
            WHERE LOWER(rw_dml.scope_id) IN (LOWER(var_myFormerScope), LOWER(var_myParentScope))
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            rw.scope_id IN (@myFormerScope, @myParentScope)
            */
            AND rw.ID = rw_dml.ID;
        EXCEPTION
            WHEN OTHERS THEN
                error_catch$ERROR_NUMBER := '0';
                error_catch$ERROR_SEVERITY := '0';
                error_catch$ERROR_LINE := '0';
                error_catch$ERROR_PROCEDURE := 'MOVEGOOTYPE';
                GET STACKED DIAGNOSTICS error_catch$ERROR_STATE = RETURNED_SQLSTATE,
                    error_catch$ERROR_MESSAGE = MESSAGE_TEXT;
                /*
                [7922 - Severity LOW - PostgreSQL uses a different approach to handle errors compared to the source code. Review the converted code and change it where necessary.]
                SELECT @ErrorMessage = ERROR_MESSAGE()
                */
                SELECT
                    error_catch$ERROR_MESSAGE
                    INTO var_ErrorMessage;
                RAISE 'Error %, severity %, state % was raised. Message: %. Argument: %. Argument: %. Argument: %', '50000', 16, 1, 'Could not move %d to %d: %s', par_ChildId, par_ParentId, var_ErrorMessage USING ERRCODE = '50000';
                ROLLBACK;
    END;
END;
$BODY$
LANGUAGE plpgsql;

