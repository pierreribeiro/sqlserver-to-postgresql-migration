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
                ON g.uid = mtm.end_point
            WHERE NOT EXISTS (SELECT
                *
                FROM perseus_dbo.m_upstream AS us
                WHERE us.start_point = mtm.end_point)
            ORDER BY g.added_on DESC NULLS LAST
            LIMIT 10000) AS d
    UNION
    (SELECT
        uid
        FROM perseus_dbo.goo
        WHERE NOT EXISTS (SELECT
            1
            FROM perseus_dbo.m_upstream
            WHERE uid = start_point)
    LIMIT 10000);
    INSERT INTO perseus_dbo.m_upstream (start_point, end_point, path, level)
    SELECT
        start_point, end_point, path, level
        FROM perseus_dbo.mcgetupstreambylist("var_UsGooUids$aws$tmp");
END;
$BODY$
LANGUAGE plpgsql;

