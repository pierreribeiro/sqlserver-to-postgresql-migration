CREATE OR REPLACE PROCEDURE perseus_dbo.addarc(IN "@MaterialUid" CITEXT, IN "@TransitionUid" CITEXT, IN "@Direction" CITEXT)
AS 
$BODY$
BEGIN
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @FormerDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
    */
    TABLE formerdownstream$addarc
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @FormerUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
    */
    TABLE formerupstream$addarc
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @DeltaDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
    */
    TABLE deltadownstream$addarc
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @DeltaUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
    */
    TABLE deltaupstream$addarc
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @NewDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
    */
    TABLE newdownstream$addarc
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @NewUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
    */
    TABLE newupstream$addarc
    (start_point CITEXT,
        end_point CITEXT,
        path CITEXT,
        level INTEGER,
        PRIMARY KEY (start_point, end_point, path));
    INSERT INTO formerdownstream$addarc (start_point, end_point, path, level)
    SELECT
        start_point, end_point, path, level
        FROM perseus_dbo.mcgetdownstream("@MaterialUid");
    INSERT INTO formerupstream$addarc (start_point, end_point, path, level)
    SELECT
        start_point, end_point, path, level
        FROM perseus_dbo.mcgetupstream("@MaterialUid");

    IF LOWER("@Direction") = LOWER('PT')
    /*
    [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
    @Direction = 'PT'
    */
    THEN
        INSERT INTO perseus_dbo.material_transition (material_id, transition_id)
        VALUES ("@MaterialUid", "@TransitionUid");
    ELSE
        INSERT INTO perseus_dbo.transition_material (material_id, transition_id)
        VALUES ("@MaterialUid", "@TransitionUid");
    END IF;
    INSERT INTO newdownstream$addarc (start_point, end_point, path, level)
    SELECT
        start_point, end_point, path, level
        FROM perseus_dbo.mcgetdownstream("@MaterialUid");
    INSERT INTO newupstream$addarc (start_point, end_point, path, level)
    SELECT
        start_point, end_point, path, level
        FROM perseus_dbo.mcgetupstream("@MaterialUid");
    INSERT INTO deltaupstream$addarc (start_point, end_point, path, level)
    SELECT
        start_point, end_point, path, level
        FROM newupstream$addarc AS n
        WHERE NOT EXISTS (SELECT
            *
            FROM formerupstream$addarc AS f
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
    INSERT INTO deltadownstream$addarc (start_point, end_point, path, level)
    SELECT
        start_point, end_point, path, level
        FROM newdownstream$addarc AS n
        WHERE NOT EXISTS (SELECT
            *
            FROM formerdownstream$addarc AS f
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

    IF (SELECT
        COUNT(*)
        FROM perseus_dbo.m_downstream
        WHERE start_point = "@MaterialUid") = 0 THEN
        INSERT INTO perseus_dbo.m_downstream (start_point, end_point, path, level)
        VALUES ("@MaterialUid", "@MaterialUid", '', 0);
    END IF;

    IF (SELECT
        COUNT(*)
        FROM perseus_dbo.m_upstream
        WHERE start_point = "@MaterialUid") = 0 THEN
        INSERT INTO perseus_dbo.m_upstream (start_point, end_point, path, level)
        VALUES ("@MaterialUid", "@MaterialUid", '', 0);
    END IF;
    /* * Add secondary downstream connections * */
    INSERT INTO perseus_dbo.m_downstream (start_point, end_point, path, level)
    SELECT
        r.end_point, n.end_point,
        CASE
            WHEN LOWER(r.path) LIKE LOWER('%/')
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            r.path LIKE '%/'
            */
            AND LOWER(n.path) LIKE LOWER('/%')
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            n.path LIKE '/%'
            */
            THEN r.path || r.start_point || n.path
            ELSE r.path || n.path
        END, r.level + n.level
        FROM deltaupstream$addarc AS r
        JOIN newdownstream$addarc AS n
            ON LOWER(r.start_point) = LOWER(n.start_point)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            r.start_point = n.start_point
            */
    UNION
    SELECT
        nu.end_point, dd.end_point, nu.path || dd.path, nu.level + dd.level
        FROM deltadownstream$addarc AS dd
        JOIN newupstream$addarc AS nu
            ON LOWER(nu.start_point) = LOWER(dd.start_point)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            nu.start_point = dd.start_point
            */;
    /* * Add secondary upstream connections * */
    INSERT INTO perseus_dbo.m_upstream (start_point, end_point, path, level)
    SELECT
        r.end_point, n.end_point,
        CASE
            WHEN LOWER(r.path) LIKE LOWER('%/')
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            r.path LIKE '%/'
            */
            AND LOWER(n.path) LIKE LOWER('/%')
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            n.path LIKE '/%'
            */
            THEN r.path || r.start_point || n.path
            ELSE r.path || n.path
        END, r.level + n.level
        FROM deltadownstream$addarc AS r
        JOIN newupstream$addarc AS n
            ON LOWER(r.start_point) = LOWER(n.start_point)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            r.start_point = n.start_point
            */
    UNION
    SELECT
        nd.end_point, du.end_point,
        CASE
            WHEN LOWER(nd.path) LIKE LOWER('%/')
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            nd.path LIKE '%/'
            */
            AND LOWER(du.path) LIKE LOWER('/%')
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            du.path LIKE '/%'
            */
            THEN nd.path || nd.start_point || du.path
            ELSE nd.path || du.path
        END, nd.level + du.level
        FROM deltaupstream$addarc AS du
        JOIN newdownstream$addarc AS nd
            ON LOWER(nd.start_point) = LOWER(du.start_point)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            nd.start_point = du.start_point
            */;
    DROP TABLE IF EXISTS formerdownstream$addarc;
    DROP TABLE IF EXISTS formerupstream$addarc;
    DROP TABLE IF EXISTS deltadownstream$addarc;
    DROP TABLE IF EXISTS deltaupstream$addarc;
    DROP TABLE IF EXISTS newdownstream$addarc;
    DROP TABLE IF EXISTS newupstream$addarc;
END;
$BODY$
LANGUAGE plpgsql;

