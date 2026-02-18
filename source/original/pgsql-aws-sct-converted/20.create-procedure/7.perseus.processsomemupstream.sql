CREATE OR REPLACE PROCEDURE perseus_dbo.processsomemupstream(IN "@dirty_in" perseus_dbo.goolist, IN "@clean_in" perseus_dbo.goolist, INOUT p_refcur refcursor)
AS 
$BODY$
/* DROP PROCEDURE [dbo].[ProcessSomeMUpstream] */
DECLARE
    var_add_rows INTEGER;
    var_rem_rows INTEGER;
    var_dirty_count INTEGER;
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
    TABLE oldupstream$processsomemupstream
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
    TABLE newupstream$processsomemupstream
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
    TABLE addupstream$processsomemupstream
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
    TABLE remupstream$processsomemupstream
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    PERFORM perseus_dbo.goolist$aws$f('"var_dirty$aws$tmp"');
    /* the input materials, minus any that may have already been cleaned */
    /* in a previous round */
    PERFORM perseus_dbo.goolist$aws$f('"@dirty_in$aws$tmp"');
    INSERT INTO "@dirty_in$aws$tmp"
    SELECT
        *
        FROM UNNEST(@dirty_in);
    PERFORM perseus_dbo.goolist$aws$f('"@clean_in$aws$tmp"');
    INSERT INTO "@clean_in$aws$tmp"
    SELECT
        *
        FROM UNNEST(@clean_in);
    INSERT INTO "var_dirty$aws$tmp"
    SELECT DISTINCT
        uid
        FROM "@dirty_in$aws$tmp" AS d
        WHERE NOT EXISTS (SELECT
            1
            FROM "@clean_in$aws$tmp" AS c
            WHERE c.uid = d.uid);
    /*
    -- add to the input materials any materials that are downstream of
    -- the input material(s), skipping those we already have or which are
    -- already in the clean list.  These will be processed as well and passed
    -- back to be added to the @clean collection in the caller.
    INSERT INTO @dirty
       SELECT DISTINCT start_point AS uid FROM m_upstream mu
         WHERE EXISTS (
           SELECT 1 FROM @dirty dl WHERE dl.uid = mu.end_point )
         AND NOT EXISTS (
           SELECT 1 FROM @dirty dl1 WHERE dl1.uid = mu.start_point )
         AND NOT EXISTS (
           SELECT 1 FROM @clean_in c WHERE c.uid = mu.start_point )
    */
    SELECT
        COUNT(*)
        INTO var_dirty_count
        FROM "var_dirty$aws$tmp";

    IF var_dirty_count > 0 THEN
        INSERT INTO oldupstream$processsomemupstream (start_point, end_point, path, level)
        SELECT
            start_point, end_point, path, level
            FROM perseus_dbo.m_upstream
            JOIN "var_dirty$aws$tmp" AS d
                ON d.uid = m_upstream.start_point;
        INSERT INTO newupstream$processsomemupstream
        SELECT
            start_point, end_point, path, level
            FROM perseus_dbo.mcgetupstreambylist("var_dirty$aws$tmp");
        /* * determine what, if any inserts are needed * */
        INSERT INTO addupstream$processsomemupstream (start_point, end_point, path, level)
        SELECT
            start_point, end_point, path, level
            FROM newupstream$processsomemupstream AS n
            WHERE NOT EXISTS (SELECT
                1
                FROM oldupstream$processsomemupstream AS f
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
        INSERT INTO remupstream$processsomemupstream (start_point, end_point, path, level)
        SELECT
            start_point, end_point, path, level
            FROM oldupstream$processsomemupstream AS o
            WHERE NOT EXISTS (SELECT
                1
                FROM newupstream$processsomemupstream AS n
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
            FROM addupstream$processsomemupstream;
        SELECT
            COUNT(*)
            INTO var_rem_rows
            FROM remupstream$processsomemupstream;

        IF var_add_rows > 0 THEN
            /* * Insert New Rows * */
            INSERT INTO perseus_dbo.m_upstream (start_point, end_point, path, level)
            SELECT
                start_point, end_point, path, level
                FROM addupstream$processsomemupstream;
        END IF;

        IF var_rem_rows > 0 THEN
            /* * Delete Obsolete Rows * */
            DELETE FROM perseus_dbo.m_upstream
                WHERE start_point IN (SELECT
                    uid
                    FROM "var_dirty$aws$tmp") AND NOT EXISTS (SELECT
                    1
                    FROM newupstream$processsomemupstream AS f
                    WHERE f.start_point = m_upstream.start_point AND f.end_point = m_upstream.end_point AND f.path = m_upstream.path);
        END IF;
    END IF;
    /* return the list of processed start_point nodes. */
    OPEN p_refcur FOR
    SELECT
        *
        FROM "var_dirty$aws$tmp";
    DROP TABLE IF EXISTS oldupstream$processsomemupstream;
    DROP TABLE IF EXISTS newupstream$processsomemupstream;
    DROP TABLE IF EXISTS addupstream$processsomemupstream;
    DROP TABLE IF EXISTS remupstream$processsomemupstream;
END;
$BODY$
LANGUAGE plpgsql;

