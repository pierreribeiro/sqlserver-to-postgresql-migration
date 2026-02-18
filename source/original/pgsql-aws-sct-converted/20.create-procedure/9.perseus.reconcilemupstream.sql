CREATE OR REPLACE PROCEDURE perseus_dbo.reconcilemupstream()
AS 
$BODY$
DECLARE
    var_add_rows INTEGER;
    var_rem_rows INTEGER;
    var_dirty_count INTEGER;
    var_ErrorMessage CITEXT;
    var_ErrorSeverity INTEGER;
    var_ErrorState INTEGER;
BEGIN
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @OldUpstream TABLE(
                          start_point VARCHAR(50),
                          end_point VARCHAR(50),
                          path VARCHAR(500),
                          level INT,
                          PRIMARY KEY (start_point, end_point, path))
    */
    TABLE oldupstream$reconcilemupstream
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @NewUpstream TABLE(
                          start_point VARCHAR(50),
                          end_point VARCHAR(50),
                          path VARCHAR(500),
                          level INT,
                          PRIMARY KEY (start_point, end_point, path))
    */
    TABLE newupstream$reconcilemupstream
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @AddUpstream TABLE(
                          start_point VARCHAR(50),
                          end_point VARCHAR(50),
                          path VARCHAR(500),
                          level INT,
                          PRIMARY KEY (start_point, end_point, path))
    */
    TABLE addupstream$reconcilemupstream
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @RemUpstream TABLE (
                          start_point VARCHAR(50),
                          end_point VARCHAR(50),
                          path VARCHAR(500),
                          level INT,
                          PRIMARY KEY (start_point, end_point, path))
    */
    TABLE remupstream$reconcilemupstream
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    /* not sure where declared, but it's what McGetUpStreamByList expects */
    /* embedding the recursive query, or a call directory to the view upstream */
    /* from within the proc doesn't work, for reasons are presently unclear to */
    /* me -dolan 2015-08-07 */
    PERFORM perseus_dbo.goolist$aws$f('"var_dirty$aws$tmp"');

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
        INSERT INTO "var_dirty$aws$tmp"
        SELECT DISTINCT
            material_uid AS uid
            FROM perseus_dbo.m_upstream_dirty_leaves
            WHERE material_uid != 'n/a'
            LIMIT 10;
        INSERT INTO "var_dirty$aws$tmp"
        SELECT DISTINCT
            start_point AS uid
            FROM perseus_dbo.m_upstream AS mu
            WHERE EXISTS (SELECT
                1
                FROM "var_dirty$aws$tmp" AS dl
                WHERE dl.uid = mu.end_point) AND NOT EXISTS (SELECT
                1
                FROM "var_dirty$aws$tmp" AS dl1
                WHERE dl1.uid = mu.start_point) AND start_point != 'n/a';
        SELECT
            COUNT(*)
            INTO var_dirty_count
            FROM "var_dirty$aws$tmp";

        IF var_dirty_count > 0 THEN
            DELETE FROM perseus_dbo.m_upstream_dirty_leaves
                WHERE EXISTS (SELECT
                    1
                    FROM "var_dirty$aws$tmp" AS d
                    WHERE d.uid = m_upstream_dirty_leaves.material_uid);
            INSERT INTO oldupstream$reconcilemupstream (start_point, end_point, path, level)
            SELECT
                start_point, end_point, path, level
                FROM perseus_dbo.m_upstream
                JOIN "var_dirty$aws$tmp" AS d
                    ON d.uid = m_upstream.start_point;
            INSERT INTO newupstream$reconcilemupstream
            SELECT
                start_point, end_point, path, level
                FROM perseus_dbo.mcgetupstreambylist("var_dirty$aws$tmp");
            /* * determine what, if any inserts are needed * */
            INSERT INTO addupstream$reconcilemupstream (start_point, end_point, path, level)
            SELECT
                start_point, end_point, path, level
                FROM newupstream$reconcilemupstream AS n
                WHERE NOT EXISTS (SELECT
                    1
                    FROM oldupstream$reconcilemupstream AS f
                    WHERE LOWER(f.start_point) = LOWER(n.start_point)
                    /*
                    [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                    f.start_point = n.start_point
                    */
                    AND LOWER(f.end_point) = LOWER(n.end_point)
                    /*
                    [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                    f.end_point = n.end_point
                    */
                    AND LOWER(f.path) = LOWER(n.path)
                    /*
                    [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                    f.path = n.path
                    */);
            /*
            * Delete Obsolete Rows.  This (hopefully) serves to check
               for deletes before unnecessarily locking the table.
            *
            */
            INSERT INTO remupstream$reconcilemupstream (start_point, end_point, path, level)
            SELECT
                start_point, end_point, path, level
                FROM oldupstream$reconcilemupstream AS o
                WHERE NOT EXISTS (SELECT
                    1
                    FROM newupstream$reconcilemupstream AS n
                    WHERE LOWER(n.start_point) = LOWER(o.start_point)
                    /*
                    [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                    n.start_point = o.start_point
                    */
                    AND LOWER(n.end_point) = LOWER(o.end_point)
                    /*
                    [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                    n.end_point = o.end_point
                    */
                    AND LOWER(n.path) = LOWER(o.path)
                    /*
                    [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                    n.path = o.path
                    */);
            SELECT
                COUNT(*)
                INTO var_add_rows
                FROM addupstream$reconcilemupstream;
            SELECT
                COUNT(*)
                INTO var_rem_rows
                FROM remupstream$reconcilemupstream;

            IF var_add_rows > 0 THEN
                /* * Insert New Rows * */
                INSERT INTO perseus_dbo.m_upstream (start_point, end_point, path, level)
                SELECT
                    start_point, end_point, path, level
                    FROM addupstream$reconcilemupstream;
            END IF;

            IF var_rem_rows > 0 THEN
                /* * Delete Obsolete Rows * */
                DELETE FROM perseus_dbo.m_upstream
                    WHERE start_point IN (SELECT
                        uid
                        FROM "var_dirty$aws$tmp") AND NOT EXISTS (SELECT
                        1
                        FROM newupstream$reconcilemupstream AS f
                        WHERE f.start_point = m_upstream.start_point AND f.end_point = m_upstream.end_point AND f.path = m_upstream.path);
            END IF;
        END IF;
        /*
        [7615 - Severity CRITICAL - Your code ends a transaction inside a block with exception handlers. Revise your code to move transaction control to the application side and try again.]
        COMMIT TRANSACTION
        */
        EXCEPTION
            WHEN OTHERS THEN
                error_catch$ERROR_NUMBER := '0';
                error_catch$ERROR_SEVERITY := '0';
                error_catch$ERROR_LINE := '0';
                error_catch$ERROR_PROCEDURE := 'RECONCILEMUPSTREAM';
                GET STACKED DIAGNOSTICS error_catch$ERROR_STATE = RETURNED_SQLSTATE,
                    error_catch$ERROR_MESSAGE = MESSAGE_TEXT;
                /*
                [7922 - Severity LOW - PostgreSQL uses a different approach to handle errors compared to the source code. Review the converted code and change it where necessary.]
                SELECT @ErrorMessage =
                       ERROR_MESSAGE() + ' Line ' + CAST(ERROR_LINE() AS NVARCHAR(5)),
                       @ErrorSeverity = ERROR_SEVERITY(),
                       @ErrorState = ERROR_STATE()
                */
                SELECT
                    error_catch$ERROR_MESSAGE || ' Line ' || CAST (error_catch$ERROR_LINE AS VARCHAR(5)), error_catch$ERROR_SEVERITY, error_catch$ERROR_STATE
                    INTO var_ErrorMessage, var_ErrorSeverity, var_ErrorState;
                ROLLBACK;
                RAISE 'Error %, severity %, state % was raised. Message: %.', '50000', var_ErrorSeverity, ?, var_ErrorMessage USING ERRCODE = '50000';
                DROP TABLE IF EXISTS oldupstream$reconcilemupstream;
                DROP TABLE IF EXISTS newupstream$reconcilemupstream;
                DROP TABLE IF EXISTS addupstream$reconcilemupstream;
                DROP TABLE IF EXISTS remupstream$reconcilemupstream;
    END;
END;
$BODY$
LANGUAGE plpgsql;

