CREATE OR REPLACE FUNCTION perseus_dbo.linkunlinkedmaterials()
AS
$BODY$
DECLARE
    /*
    [7702 - Severity LOW - DMS SC doesn't convert the READ_ONLY option because this is a default option for cursors in PostgreSQL. Review the converted code to make sure that it produces the same results as the source code.]
    c CURSOR READ_ONLY FAST_FORWARD FOR
             SELECT uid
               FROM goo
              WHERE NOT EXISTS
                (SELECT 1
                   FROM m_upstream
                  WHERE uid = start_point)
    */
    /*
    [7701 - Severity LOW - DMS SC doesn't convert the FAST_FORWARD option because this is a default option for cursors in PostgreSQL. Review the converted code to make sure that it produces the same results as the source code.]
    c CURSOR READ_ONLY FAST_FORWARD FOR
             SELECT uid
               FROM goo
              WHERE NOT EXISTS
                (SELECT 1
                   FROM m_upstream
                  WHERE uid = start_point)
    */
    c CURSOR FOR
    SELECT
        uid
        FROM perseus_dbo.goo
        WHERE NOT EXISTS (SELECT
            1
            FROM perseus_dbo.m_upstream
            WHERE uid = start_point);
    var_material_uid CITEXT;
BEGIN
    OPEN c;
    FETCH NEXT FROM c INTO var_material_uid;

    WHILE ((CASE FOUND::INT
        WHEN 0 THEN - 1
        ELSE 0
    END) = 0) LOOP
        BEGIN
            INSERT INTO perseus_dbo.m_upstream (start_point, end_point, level, path)
            SELECT
                start_point, end_point, level, path
                FROM perseus_dbo.mcgetupstream(var_material_uid::NUMERIC(18, 0));
            EXCEPTION
                WHEN OTHERS THEN
                    /* ignore errors */
                    BEGIN
                    END;
        END;
        FETCH NEXT FROM c INTO var_material_uid;
    END LOOP;
    CLOSE c;
END;
$BODY$
LANGUAGE  plpgsql;

