CREATE OR REPLACE FUNCTION perseus_dbo.gettransfercombos(IN "@pRobotLog" INTEGER, IN "@pRobotRun" INTEGER)
RETURNS TABLE (sourceplate VARCHAR, destinationplate VARCHAR, minrow INTEGER, maxrow INTEGER, loaded INTEGER)
AS
$BODY$
# variable_conflict use_column
DECLARE
    var_SourcePlate CITEXT;
    var_DestinationPlate CITEXT;
    var_LastSourcePlate CITEXT DEFAULT '0';
    var_LastDestinationPlate CITEXT DEFAULT '0';
    var_RowNumber INTEGER;
    var_Loaded INTEGER;
    var_AlreadyUsed INTEGER DEFAULT 0;
    cur CURSOR FOR
    SELECT
        id, sourceplate, destinationplate, loaded
        FROM listing$gettransfercombos;
BEGIN
    DROP TABLE IF EXISTS gettransfercombos$tmptbl;
    CREATE TEMPORARY TABLE gettransfercombos$tmptbl
    (sourceplate CITEXT,
        destinationplate CITEXT,
        minrow INTEGER,
        maxrow INTEGER,
        loaded INTEGER);
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @UsedCombos TABLE (SourcePlate VARCHAR(50), DestinationPlate VARCHAR(50))
    */
    TABLE usedcombos$gettransfercombos
    (sourceplate CITEXT,
        destinationplate CITEXT);
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @Listing TABLE (Id INT, SourcePlate VARCHAR(50), DestinationPlate VARCHAR(50), Loaded INT)
    */
    TABLE listing$gettransfercombos
    (id INTEGER,
        sourceplate CITEXT,
        destinationplate CITEXT,
        loaded INTEGER);

    IF "@pRobotLog" IS NOT NULL THEN
        INSERT INTO listing$gettransfercombos
        SELECT
            rlt.id, source_barcode, destination_barcode,
            CASE
                WHEN rl.loadable = 1 OR rl.loaded = 1 THEN 1
                ELSE 0
            END
            FROM perseus_dbo.robot_log_transfer AS rlt
            JOIN perseus_dbo.robot_log AS rl
                ON rl.id = rlt.robot_log_id
            WHERE rl.id = "@pRobotLog" AND source_barcode IS NOT NULL AND destination_barcode IS NOT NULL AND LTRIM(source_barcode)::CITEXT != '' AND LTRIM(destination_barcode)::CITEXT != ''
            ORDER BY id NULLS FIRST;
    ELSE
        INSERT INTO listing$gettransfercombos
        SELECT
            rlt.id, source_barcode, destination_barcode,
            CASE
                WHEN rl.loadable = 1 OR rl.loaded = 1 THEN 1
                ELSE 0
            END
            FROM perseus_dbo.robot_log_transfer AS rlt
            JOIN perseus_dbo.robot_log AS rl
                ON rl.id = rlt.robot_log_id
            WHERE rl.id IN (SELECT
                id
                FROM perseus_dbo.robot_log
                WHERE robot_run_id = "@pRobotRun") AND source_barcode IS NOT NULL AND destination_barcode IS NOT NULL AND LTRIM(source_barcode)::CITEXT != '' AND LTRIM(destination_barcode)::CITEXT != ''
            ORDER BY id NULLS FIRST;
    END IF;
    OPEN cur;
    FETCH NEXT FROM cur INTO var_RowNumber, var_SourcePlate, var_DestinationPlate, var_Loaded;

    WHILE (CASE FOUND::INT
        WHEN 0 THEN - 1
        ELSE 0
    END) = 0 LOOP
        SELECT
            COUNT(*)
            INTO var_AlreadyUsed
            FROM usedcombos$gettransfercombos
            WHERE LOWER(sourceplate) = LOWER(var_SourcePlate)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            SourcePlate = @SourcePlate
            */
            AND LOWER(destinationplate) = LOWER(var_DestinationPlate)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            DestinationPlate = @DestinationPlate
            */;

        IF LOWER(var_LastSourcePlate) != LOWER(var_SourcePlate)
        /*
        [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
        @LastSourcePlate != @SourcePlate
        */
        OR LOWER(var_LastDestinationPlate) != LOWER(var_DestinationPlate)
        /*
        [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
        @LastDestinationPlate != @DestinationPlate
        */
        OR var_AlreadyUsed > 0 THEN
            UPDATE gettransfercombos$tmptbl
            SET maxrow = var_RowNumber - 1
                WHERE maxrow IS NULL;
            DELETE FROM usedcombos$gettransfercombos
                WHERE LOWER(sourceplate) = LOWER(var_SourcePlate)
                /*
                [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                SourcePlate = @SourcePlate
                */
                AND LOWER(destinationplate) = LOWER(var_DestinationPlate)
                /*
                [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                DestinationPlate = @DestinationPlate
                */;
            INSERT INTO gettransfercombos$tmptbl (sourceplate, destinationplate, minrow, loaded)
            VALUES (var_SourcePlate, var_DestinationPlate, var_RowNumber, var_Loaded);
        END IF;
        INSERT INTO usedcombos$gettransfercombos (sourceplate, destinationplate)
        VALUES (var_SourcePlate, var_DestinationPlate);
        var_LastSourcePlate := var_SourcePlate;
        var_LastDestinationPlate := var_DestinationPlate;
        FETCH NEXT FROM cur INTO var_RowNumber, var_SourcePlate, var_DestinationPlate, var_Loaded;
    END LOOP;
    CLOSE cur;
    UPDATE gettransfercombos$tmptbl
    SET maxrow = var_RowNumber
        WHERE maxrow IS NULL;
    DROP TABLE IF EXISTS usedcombos$gettransfercombos;
    DROP TABLE IF EXISTS listing$gettransfercombos;
    RETURN QUERY
    SELECT
        *
        FROM gettransfercombos$tmptbl;
    DROP TABLE IF EXISTS gettransfercombos$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

