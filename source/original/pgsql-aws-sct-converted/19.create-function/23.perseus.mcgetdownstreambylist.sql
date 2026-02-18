CREATE OR REPLACE FUNCTION perseus_dbo.mcgetdownstreambylist(IN "@StartPoint" perseus_dbo.goolist)
RETURNS TABLE (start_point VARCHAR, end_point VARCHAR, neighbor VARCHAR, path VARCHAR, level INTEGER)
AS
$BODY$
# variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS mcgetdownstreambylist$tmptbl;
    CREATE TEMPORARY TABLE mcgetdownstreambylist$tmptbl
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
    WITH RECURSIVE downstream
    AS (SELECT
        pt.source_material AS start_point, pt.source_material AS parent, pt.destination_material AS child, CAST ('/' AS VARCHAR(500)) AS path, 1 AS level
        FROM perseus_dbo.translated AS pt
        JOIN "@StartPoint$aws$tmp" AS sp
            ON pt.source_material = sp.uid
    UNION ALL
    SELECT
        r.start_point, pt.source_material, pt.destination_material, CAST (r.path || r.child || '/' AS VARCHAR(500)), r.level + 1
        FROM perseus_dbo.translated AS pt
        JOIN downstream AS r
            ON pt.source_material = r.child
        WHERE pt.source_material != pt.destination_material)
    INSERT INTO mcgetdownstreambylist$tmptbl
    SELECT
        start_point, child AS end_point, parent, path, level
        FROM downstream;
    INSERT INTO mcgetdownstreambylist$tmptbl
    SELECT
        uid, uid, NULL, '', 0
        FROM "@StartPoint$aws$tmp";
    RETURN QUERY
    SELECT
        *
        FROM mcgetdownstreambylist$tmptbl;
    DROP TABLE IF EXISTS mcgetdownstreambylist$tmptbl;
    RETURN;
END;
/* SELECT * FROM McGetUpStream('m8700') */
$BODY$
LANGUAGE  plpgsql;

