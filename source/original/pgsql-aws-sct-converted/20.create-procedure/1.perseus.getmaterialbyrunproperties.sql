CREATE OR REPLACE PROCEDURE perseus_dbo.getmaterialbyrunproperties(IN "@RunId" CITEXT, IN "@HourTimePoint" NUMERIC, INOUT return_code int DEFAULT 0)
AS 
$BODY$
DECLARE
    var_CreatorId INTEGER;
    var_SecondTimePoint INTEGER;
    var_OriginalGoo CITEXT;
    var_StartTime TIMESTAMP WITHOUT TIME ZONE;
    var_TimePointGoo CITEXT;
    var_MaxGooIdentifier INTEGER;
    var_MaxFsIdentifier INTEGER;
    var_Split CITEXT;
BEGIN
    var_SecondTimePoint := ("@HourTimePoint" * 60 * 60)::INT;
    SELECT
        g.added_by, g.uid, r.start_time
        INTO var_CreatorId, var_OriginalGoo, var_StartTime
        FROM perseus_hermes.run AS r
        JOIN perseus_dbo.goo AS g
            ON g.uid = r.resultant_material
        WHERE LOWER((CAST (r.experiment_id AS VARCHAR(10)) || '-' || CAST (r.local_id AS VARCHAR(5)))::CITEXT) = LOWER("@RunId")
        /*
        [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
        CAST(r.experiment_id AS VARCHAR(10)) + '-' + CAST(r.local_id AS VARCHAR(5)) = @RunId
        */;

    IF var_OriginalGoo IS NOT NULL THEN
        SELECT
            regexp_replace(g.uid, 'm', '', 'gi')
            INTO var_TimePointGoo
            FROM perseus_dbo.mcgetdownstream(var_OriginalGoo)
                AS d
            JOIN perseus_dbo.goo AS g
                ON d.end_point = g.uid
            WHERE g.added_on = var_StartTime + (var_SecondTimePoint::NUMERIC || ' SECOND')::INTERVAL AND g.goo_type_id = 9;

        IF var_TimePointGoo IS NULL THEN
            SELECT
                MAX(CAST (SUBSTR(uid, 2, 100) AS INTEGER)) + 1
                INTO var_MaxGooIdentifier
                FROM perseus_dbo.goo
                WHERE uid LIKE 'm%';
            SELECT
                MAX(CAST (SUBSTR(uid, 2, 100) AS INTEGER)) + 1
                INTO var_MaxFsIdentifier
                FROM perseus_dbo.fatsmurf
                WHERE uid LIKE 's%';
            var_TimePointGoo := 'm' || CAST (var_MaxGooIdentifier AS VARCHAR(49));
            var_Split := 's' || CAST (var_MaxFsIdentifier AS VARCHAR(49));
            INSERT INTO perseus_dbo.goo (uid, name, original_volume, added_on, added_by, goo_type_id)
            VALUES (var_TimePointGoo, 'Sample TP: ' || CAST ("@HourTimePoint" AS VARCHAR(10)), .00001, var_StartTime + (var_SecondTimePoint::NUMERIC || ' SECOND')::INTERVAL, var_CreatorId, 9);
            INSERT INTO perseus_dbo.fatsmurf (uid, added_on, added_by, smurf_id, run_on)
            VALUES (var_Split, clock_timestamp(), var_CreatorId, 110, var_StartTime + (var_SecondTimePoint::NUMERIC || ' SECOND')::INTERVAL);
            CALL perseus_dbo.materialtotransition(var_OriginalGoo, var_Split);
            CALL perseus_dbo.transitiontomaterial(var_Split, var_TimePointGoo);
        END IF;
    END IF;
    return_code := CAST (regexp_replace(var_TimePointGoo, 'm', '', 'gi') AS INTEGER);
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

