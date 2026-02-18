CREATE OR REPLACE FUNCTION perseus_dbo.mcgetupstreambylist(IN "@StartPoint" perseus_dbo.goolist)
RETURNS TABLE (start_point VARCHAR, end_point VARCHAR, neighbor VARCHAR, path VARCHAR, level INTEGER)
AS
$BODY$
# variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS mcgetupstreambylist$tmptbl;
    CREATE TEMPORARY TABLE mcgetupstreambylist$tmptbl
    (start_point CITEXT,
        end_point CITEXT,
        neighbor CITEXT,
        path CITEXT,
        level INTEGER);
    PERFORM perseus_dbo.goolist$aws$f('"@StartPoint$aws$tmp"');
    INSERT INTO "@StartPoint$aws$tmp"
    SELECT
        *
        FROM UNNEST(@StartPoint);
    WITH RECURSIVE upstream
    AS (SELECT
        pt.destination_material AS start_point, pt.destination_material AS parent, pt.source_material AS child, CAST ('/' AS VARCHAR(500)) AS path, 1 AS level
        FROM perseus_dbo.translated AS pt
        JOIN "@StartPoint$aws$tmp" AS sp
            ON sp.uid = pt.destination_material
    UNION ALL
    SELECT
        r.start_point, pt.destination_material, pt.source_material, CAST (r.path || r.child || '/' AS VARCHAR(500)), r.level + 1
        FROM perseus_dbo.translated AS pt
        JOIN upstream AS r
            ON pt.destination_material = r.child
        WHERE pt.destination_material != pt.source_material)
    INSERT INTO mcgetupstreambylist$tmptbl
    SELECT
        start_point, child AS end_point, parent, path, level
        FROM upstream;
    INSERT INTO mcgetupstreambylist$tmptbl
    SELECT
        sp.uid, sp.uid, NULL, '', 0
        FROM "@StartPoint$aws$tmp" AS sp
        WHERE EXISTS (SELECT
            1
            FROM perseus_dbo.goo
            WHERE sp.uid = goo.uid);
    RETURN QUERY
    SELECT
        *
        FROM mcgetupstreambylist$tmptbl;
    DROP TABLE IF EXISTS mcgetupstreambylist$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

