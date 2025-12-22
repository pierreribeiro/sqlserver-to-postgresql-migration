CREATE OR REPLACE FUNCTION perseus_dbo.getreadcombos(IN "@pRobotLog" INTEGER, IN "@RobotRun" INTEGER)
RETURNS TABLE (sourceplate VARCHAR, minrow INTEGER, maxrow INTEGER, loaded INTEGER)
AS
$BODY$
# variable_conflict use_column
DECLARE
    var_SourcePlate CITEXT;
    var_ReadIdentifier CITEXT;
    var_LastSourcePlate CITEXT DEFAULT '0';
    var_RowNumber INTEGER;
    var_AlreadyUsed INTEGER DEFAULT 0;
    var_Loaded INTEGER;
    cur CURSOR FOR
    SELECT
        id, sourceplate, readidentifier, loaded
        FROM listing$getreadcombos;
BEGIN
    DROP TABLE IF EXISTS getreadcombos$tmptbl;
    CREATE TEMPORARY TABLE getreadcombos$tmptbl
    (sourceplate CITEXT,
        minrow INTEGER,
        maxrow INTEGER,
        loaded INTEGER);
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @UsedCombos TABLE (SourcePlate VARCHAR(50), ReadIdentifier VARCHAR(50))
    */
    TABLE usedcombos$getreadcombos
    (sourceplate CITEXT,
        readidentifier CITEXT);
    CREATE TEMPORARY
    /*
    [7659 - Severity LOW - If you use recursion, make sure that table variables in your source database and temporary tables in your target database have the same scope. Review the converted code to make sure that is produces the same results as the source code.]
    @Listing TABLE (Id INT, SourcePlate VARCHAR(50), ReadIdentifier VARCHAR(50), Loaded INT)
    */
    TABLE listing$getreadcombos
    (id INTEGER,
        sourceplate CITEXT,
        readidentifier CITEXT,
        loaded INTEGER);

    IF "@pRobotLog" IS NOT NULL THEN
        INSERT INTO listing$getreadcombos
        SELECT
            rlr.id, source_barcode, property_id,
            CASE
                WHEN rl.loadable = 1 OR rl.loaded = 1 THEN 1
                ELSE 0
            END
            FROM perseus_dbo.robot_log_read AS rlr
            JOIN perseus_dbo.robot_log AS rl
                ON rl.id = rlr.robot_log_id
            WHERE rl.id = "@pRobotLog" AND source_barcode IS NOT NULL AND LTRIM(source_barcode)::CITEXT != ''
            ORDER BY id NULLS FIRST;
    ELSE
        INSERT INTO listing$getreadcombos
        SELECT
            rlr.id, source_barcode, property_id,
            CASE
                WHEN rl.loadable = 1 OR rl.loaded = 1 THEN 1
                ELSE 0
            END
            FROM perseus_dbo.robot_log_read AS rlr
            JOIN perseus_dbo.robot_log AS rl
                ON rl.id = rlr.robot_log_id
            WHERE rl.id IN (SELECT
                id
                FROM perseus_dbo.robot_log
                WHERE robot_run_id = "@RobotRun") AND source_barcode IS NOT NULL AND LTRIM(source_barcode)::CITEXT != ''
            ORDER BY id NULLS FIRST;
    END IF;
    OPEN cur;
    FETCH NEXT FROM cur INTO var_RowNumber, var_SourcePlate, var_ReadIdentifier, var_Loaded;

    WHILE (CASE FOUND::INT
        WHEN 0 THEN - 1
        ELSE 0
    END) = 0 LOOP
        SELECT
            COUNT(*)
            INTO var_AlreadyUsed
            FROM usedcombos$getreadcombos
            WHERE LOWER(sourceplate) = LOWER(var_SourcePlate)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            SourcePlate = @SourcePlate
            */
            AND LOWER(COALESCE(readidentifier, 0)) = LOWER(var_ReadIdentifier)
            /*
            [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
            ISNULL(ReadIdentifier, 0) = @ReadIdentifier
            */;

        IF LOWER(var_LastSourcePlate) != LOWER(var_SourcePlate)
        /*
        [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
        @LastSourcePlate != @SourcePlate
        */
        OR var_AlreadyUsed > 0 THEN
            UPDATE getreadcombos$tmptbl
            SET maxrow = var_RowNumber - 1
                WHERE maxrow IS NULL;
            DELETE FROM usedcombos$getreadcombos
                WHERE LOWER(sourceplate) = LOWER(var_SourcePlate)
                /*
                [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
                SourcePlate = @SourcePlate
                */;
            INSERT INTO getreadcombos$tmptbl (sourceplate, minrow, loaded)
            VALUES (var_SourcePlate, var_RowNumber, var_Loaded);
        END IF;
        INSERT INTO usedcombos$getreadcombos (sourceplate, readidentifier)
        VALUES (var_SourcePlate, var_ReadIdentifier);
        var_LastSourcePlate := var_SourcePlate;
        FETCH NEXT FROM cur INTO var_RowNumber, var_SourcePlate, var_ReadIdentifier, var_Loaded;
    END LOOP;
    CLOSE cur;
    UPDATE getreadcombos$tmptbl
    SET maxrow = var_RowNumber
        WHERE maxrow IS NULL;
    DROP TABLE IF EXISTS usedcombos$getreadcombos;
    DROP TABLE IF EXISTS listing$getreadcombos;
    RETURN QUERY
    SELECT
        *
        FROM getreadcombos$tmptbl;
    DROP TABLE IF EXISTS getreadcombos$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

