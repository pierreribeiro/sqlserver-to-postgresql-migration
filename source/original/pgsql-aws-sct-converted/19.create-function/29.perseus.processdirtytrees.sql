CREATE OR REPLACE FUNCTION perseus_dbo.processdirtytrees()
AS
$BODY$
/* DROP PROCEDURE [dbo].[ProcessDirtyTrees] */
/* not sure where declared, but it's what McGetUpStreamByList expects */
/* embedding the recursive query, or a call directory to the view upstream */
/* from within the proc doesn't work, for reasons are presently unclear to */
/* me -dolan 2015-08-07 */
DECLARE
    var_add_rows INTEGER;
    var_rem_rows INTEGER;
    var_dirty_count INTEGER;
    var_start_time TIMESTAMP WITHOUT TIME ZONE;
    var_duration INTEGER;
    var_current CITEXT;
    var_ErrorMessage CITEXT;
    var_ErrorSeverity INTEGER;
    var_ErrorState INTEGER;
BEGIN
    PERFORM perseus_dbo.goolist$aws$f('"var_dirty$aws$tmp"');
    PERFORM perseus_dbo.goolist$aws$f('"var_to_process$aws$tmp"');
    PERFORM perseus_dbo.goolist$aws$f('"var_clean$aws$tmp"');

    DECLARE
        error_catch$ERROR_NUMBER TEXT;
        error_catch$ERROR_SEVERITY TEXT;
        error_catch$ERROR_STATE TEXT;
        error_catch$ERROR_LINE TEXT;
        error_catch$ERROR_PROCEDURE TEXT;
        error_catch$ERROR_MESSAGE TEXT;
    BEGIN
        /*
        [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
        BEGIN TRANSACTION
        */
        SELECT
            clock_timestamp()
            INTO var_start_time;
        INSERT INTO "var_dirty$aws$tmp"
        SELECT DISTINCT
            material_uid AS uid
            FROM perseus_dbo.m_upstream_dirty_leaves;
        INSERT INTO "var_clean$aws$tmp"
        VALUES ('n/a');
        SELECT
            COUNT(*)
            INTO var_dirty_count
            FROM "var_dirty$aws$tmp";
        SELECT
            0
            INTO var_duration;

        WHILE (var_dirty_count > 0 AND var_duration < 4000) LOOP
            INSERT INTO "var_to_process$aws$tmp"
            SELECT DISTINCT
                *
                FROM "var_dirty$aws$tmp"
                LIMIT 1;
            var_current := (SELECT
                *
                FROM "var_dirty$aws$tmp"
                LIMIT 1);
            /* [9996 - Severity CRITICAL - Transformer error occurred in executeStatement. Please submit report to developers.] */
            /*
            [9996 - Severity CRITICAL - Transformer error occurred in statement. Please submit report to developers.]
            INSERT @clean EXEC ProcessSomeMUpstream @to_process, @clean
            */
            DELETE FROM var_dirty AS d
            USING "var_dirty$aws$tmp" AS d
                WHERE EXISTS (SELECT
                    1
                    FROM "var_clean$aws$tmp" AS c
                    WHERE c.uid = d.uid);
            SELECT
                COUNT(*)
                INTO var_dirty_count
                FROM "var_dirty$aws$tmp";
            SELECT
                aws_sqlserver_ext.datediff('millisecond', var_start_time::TIMESTAMP, clock_timestamp()::TIMESTAMP)
                INTO var_duration;
        END LOOP;
        DELETE FROM perseus_dbo.m_upstream_dirty_leaves AS d
            WHERE EXISTS (SELECT
                1
                FROM "var_clean$aws$tmp" AS c
                WHERE c.uid = d.material_uid);
        /*
        [7615 - Severity CRITICAL - Your code ends a transaction inside a block with exception handlers. Revise your code to move transaction control to the application side and try again.]
        COMMIT TRANSACTION
        */
        EXCEPTION
            WHEN OTHERS THEN
                error_catch$ERROR_NUMBER := '0';
                error_catch$ERROR_SEVERITY := '0';
                error_catch$ERROR_LINE := '0';
                error_catch$ERROR_PROCEDURE := 'PROCESSDIRTYTREES';
                GET STACKED DIAGNOSTICS error_catch$ERROR_STATE = RETURNED_SQLSTATE,
                    error_catch$ERROR_MESSAGE = MESSAGE_TEXT;
                /*
                [7922 - Severity LOW - PostgreSQL uses a different approach to handle errors compared to the source code. Review the converted code and change it where necessary.]
                SELECT @ErrorMessage =
                       ERROR_MESSAGE() + ' Line ' + CAST(ERROR_LINE() AS NVARCHAR(5)) + '.  Possible culprint: ' + @current,
                       @ErrorSeverity = ERROR_SEVERITY(),
                       @ErrorState = ERROR_STATE()
                */
                SELECT
                    error_catch$ERROR_MESSAGE || ' Line ' || CAST (error_catch$ERROR_LINE AS VARCHAR(5)) || '.  Possible culprint: ' || var_current, error_catch$ERROR_SEVERITY, error_catch$ERROR_STATE
                    INTO var_ErrorMessage, var_ErrorSeverity, var_ErrorState;
                /*
                [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
                ROLLBACK TRANSACTION
                */
                RAISE 'Error %, severity %, state % was raised. Message: %.', '50000', var_ErrorSeverity, ?, var_ErrorMessage USING ERRCODE = '50000';
    END;
END;
$BODY$
LANGUAGE  plpgsql;

