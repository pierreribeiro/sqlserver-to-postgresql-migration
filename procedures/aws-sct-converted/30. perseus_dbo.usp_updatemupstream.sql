CREATE OR REPLACE PROCEDURE perseus_dbo.usp_updatemupstream()
AS 
$BODY$
BEGIN
    /* SET NOCOUNT ON added to prevent extra result sets from */
    /* interfering with SELECT statements. */
    PERFORM perseus_dbo.goolist$aws$f('"var_UsGooUids$aws$tmp"');
    INSERT INTO "var_UsGooUids$aws$tmp"
    SELECT DISTINCT
        uid
        FROM (SELECT
            g.uid
            FROM perseus_dbo.material_transition_material AS mtm
            JOIN perseus_dbo.goo AS g
                ON LOWER(g.uid) = LOWER(mtm.end_point)
                /*
                [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                g.uid = mtm.end_point
                */
            WHERE NOT EXISTS (SELECT
                *
                FROM perseus_dbo.m_upstream AS us
                WHERE LOWER(us.start_point) = LOWER(mtm.end_point)
                /*
                [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                us.start_point = mtm.end_point
                */)
            ORDER BY g.added_on DESC NULLS LAST
            LIMIT 10000) AS d
    UNION
    (SELECT
        uid
        FROM perseus_dbo.goo
        WHERE NOT EXISTS (SELECT
            1
            FROM perseus_dbo.m_upstream
            WHERE LOWER(uid) = LOWER(start_point)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            uid = start_point
            */)
    LIMIT 10000);
    INSERT INTO perseus_dbo.m_upstream (start_point, end_point, path, level)
    SELECT
        start_point, end_point, path, level
        FROM perseus_dbo.mcgetupstreambylist("var_UsGooUids$aws$tmp");
END;
$BODY$
LANGUAGE plpgsql;

