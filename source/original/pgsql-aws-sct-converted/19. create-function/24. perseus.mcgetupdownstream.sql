CREATE OR REPLACE FUNCTION perseus_dbo.mcgetupdownstream(IN "@StartPoint" CITEXT)
RETURNS TABLE (start_point VARCHAR, end_point VARCHAR, neighbor VARCHAR, path VARCHAR, level INTEGER)
AS
$BODY$
# variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS mcgetupdownstream$tmptbl;
    CREATE TEMPORARY TABLE mcgetupdownstream$tmptbl
    (start_point CITEXT,
        end_point CITEXT,
        neighbor CITEXT,
        path CITEXT,
        level INTEGER);
    INSERT INTO mcgetupdownstream$tmptbl
    SELECT
        *
        FROM perseus_dbo.mcgetupstream("@StartPoint");
    INSERT INTO mcgetupdownstream$tmptbl
    SELECT
        *
        FROM perseus_dbo.mcgetdownstream("@StartPoint");
    DELETE FROM mcgetupdownstream$tmptbl
        WHERE LOWER(end_point) = LOWER("@StartPoint")
        /*
        [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
        end_point = @StartPoint
        */;
    INSERT INTO mcgetupdownstream$tmptbl
    VALUES ("@StartPoint", "@StartPoint", NULL, '', 0);
    RETURN QUERY
    SELECT
        *
        FROM mcgetupdownstream$tmptbl;
    DROP TABLE IF EXISTS mcgetupdownstream$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

