CREATE OR REPLACE FUNCTION perseus_dbo.getupstreammasses(IN "@StartPoint" CITEXT)
RETURNS TABLE (end_point VARCHAR, mass DOUBLE PRECISION, level INTEGER)
AS
$BODY$
# variable_conflict use_column
DECLARE
    var_UsUid CITEXT;
    var_MassCalcId INTEGER;
    us_cur CURSOR FOR
    SELECT
        end_point, id
        FROM masscalc$getupstreammasses
        WHERE mass IS NOT NULL;
BEGIN
    DROP TABLE IF EXISTS getupstreammasses$tmptbl;
    CREATE TEMPORARY TABLE getupstreammasses$tmptbl
    (end_point CITEXT,
        mass DOUBLE PRECISION,
        level INTEGER);
    /* DECLARE @StartPoint NVARCHAR(50) */
    /* SET @StartPoint = 'm153677' */
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @MassCalc TABLE (id INT IDENTITY(1,1), end_point NVARCHAR(50), mass float, path NVARCHAR(250), level INT)
    */
    TABLE masscalc$getupstreammasses
    (id BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
        end_point CITEXT,
        mass DOUBLE PRECISION,
        path CITEXT,
        level INTEGER);
    INSERT INTO masscalc$getupstreammasses (end_point, mass, path, level)
    SELECT
        us.end_point, NULLIF(g.original_mass, 0), us.path, us.level
        FROM perseus_dbo.getunprocessedupstream("@StartPoint"::NUMERIC(18, 0))
            AS us
        JOIN perseus_dbo.goo AS g
            ON g.uid = us.end_point AND (g.container_id IS NULL OR COALESCE(g.original_mass, 0) = 0)
        WHERE us.level > 0;
    /* SELECT * FROM @MassCalc */
    DELETE FROM masscalc$getupstreammasses
        WHERE id IN (SELECT
            mc_us.id
            FROM masscalc$getupstreammasses AS mc_ds
            JOIN masscalc$getupstreammasses AS mc_us
                ON LOWER(mc_us.path) LIKE LOWER('%/' || mc_ds.end_point || '/%')
                /*
                [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                mc_us.path LIKE '%/' + mc_ds.end_point + '/%'
                */
                AND mc_ds.level < mc_us.level
            WHERE mc_ds.mass IS NOT NULL);
    /* SELECT * FROM @MassCalc */
    DELETE FROM masscalc$getupstreammasses
        WHERE id IN (SELECT
            mc_us.id
            FROM masscalc$getupstreammasses AS mc_ds
            JOIN masscalc$getupstreammasses AS mc_us
                ON LOWER(mc_us.path) LIKE LOWER('%/' || mc_ds.end_point || '/%')
                /*
                [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                mc_us.path LIKE '%/' + mc_ds.end_point + '/%'
                */
                AND mc_ds.level < mc_us.level
            WHERE mc_us.mass IS NULL);
    OPEN us_cur;
    FETCH NEXT FROM us_cur INTO var_UsUid, var_MassCalcId;

    WHILE (CASE FOUND::INT
        WHEN 0 THEN - 1
        ELSE 0
    END) = 0 LOOP
        IF (SELECT
            COUNT(*)
            FROM perseus_dbo.mcgetdownstream(var_UsUid::NUMERIC(18, 0))
                AS ds
            WHERE ds.end_point NOT IN (SELECT
                end_point
                FROM masscalc$getupstreammasses) AND LOWER(ds.end_point) != LOWER("@StartPoint")
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            ds.end_point != @StartPoint
            */) > 1 THEN
            DELETE FROM masscalc$getupstreammasses
                WHERE id = var_MassCalcId;
        END IF;
        FETCH NEXT FROM us_cur INTO var_UsUid, var_MassCalcId;
    END LOOP;
    CLOSE us_cur;
    INSERT INTO getupstreammasses$tmptbl
    SELECT
        end_point, mass, level
        FROM masscalc$getupstreammasses
        WHERE mass IS NOT NULL
    UNION
    SELECT
        mc2.end_point, mc2.mass, mc2.level
        FROM masscalc$getupstreammasses AS mc1
        JOIN masscalc$getupstreammasses AS mc2
            ON LOWER(mc2.path) LIKE LOWER('%' || mc1.end_point || '%')
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            mc2.path LIKE '%' + mc1.end_point + '%'
            */
        WHERE mc2.mass IS NULL AND mc1.mass IS NULL
    UNION
    SELECT
        mc1.end_point, mc1.mass, mc1.level
        FROM masscalc$getupstreammasses AS mc1
        WHERE mc1.mass IS NULL AND NOT EXISTS (SELECT
            *
            FROM masscalc$getupstreammasses AS mc2
            WHERE LOWER(mc2.path) LIKE LOWER('%' || mc1.end_point || '%')
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            mc2.path LIKE '%' + mc1.end_point + '%'
            */)
    UNION
    SELECT
        mc1.end_point, mc1.mass, mc1.level
        FROM masscalc$getupstreammasses AS mc1
        WHERE mc1.mass IS NULL AND EXISTS (SELECT
            *
            FROM masscalc$getupstreammasses AS mc2
            WHERE LOWER(mc2.path) LIKE LOWER('%' || mc1.end_point || '%')
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            mc2.path LIKE '%' + mc1.end_point + '%'
            */
            AND mc2.mass IS NULL);
    DROP TABLE IF EXISTS masscalc$getupstreammasses;
    RETURN QUERY
    SELECT
        *
        FROM getupstreammasses$tmptbl;
    DROP TABLE IF EXISTS getupstreammasses$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

