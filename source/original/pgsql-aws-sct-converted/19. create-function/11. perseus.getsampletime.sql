CREATE OR REPLACE FUNCTION perseus_dbo.getsampletime(IN "@StartPoint" CITEXT)
RETURNS CITEXT
AS
$BODY$
/*
A faster version of sample time for perseus.
Uses a recursive query to find the first parent that is a result of a fermentation.
That's considered the "Sample".
*/
/* DROP FUNCTION [dbo].[GetSampleTime] */
DECLARE
    var_fermentation_uid CITEXT;
    var_material_uid CITEXT;
    var_sample_uid CITEXT;
    var_result DOUBLE PRECISION;
BEGIN
    WITH RECURSIVE upstream
    AS (SELECT
        mtm.source_uid, mtm.destination_uid, mtm.transition_uid, fs.smurf_id AS transition_type_id, 1 AS level
        FROM perseus_dbo.vw_material_transition_material_up AS mtm
        JOIN perseus_dbo.fatsmurf AS fs
            ON fs.uid = mtm.transition_uid AND fs.smurf_id IN (110, 111, 22, 365)
        WHERE mtm.destination_uid = "@StartPoint"
    UNION ALL
    SELECT
        mtm.source_uid, mtm.destination_uid, mtm.transition_uid, fs.smurf_id AS transition_type_id, r.level + 1
        FROM perseus_dbo.vw_material_transition_material_up AS mtm
        JOIN perseus_dbo.fatsmurf AS fs
            ON fs.uid = mtm.transition_uid
        JOIN upstream AS r
            ON r.source_uid = mtm.destination_uid AND fs.smurf_id IN (110, 111, 22, 365))
    SELECT
        transition_uid, destination_uid
        INTO var_fermentation_uid, var_material_uid
        FROM upstream
        WHERE transition_type_id = 22
        ORDER BY level ASC NULLS FIRST
        LIMIT 1;
    WITH RECURSIVE upstream
    AS (SELECT
        mtm.source_uid, mtm.destination_uid, mtm.transition_uid, fs.smurf_id AS transition_type_id, 1 AS level
        FROM perseus_dbo.vw_material_transition_material_up AS mtm
        JOIN perseus_dbo.fatsmurf AS fs
            ON fs.uid = mtm.transition_uid AND fs.smurf_id IN (110, 111, 365)
        WHERE mtm.destination_uid = "@StartPoint"
    UNION ALL
    SELECT
        mtm.source_uid, mtm.destination_uid, mtm.transition_uid, fs.smurf_id AS transition_type_id, r.level + 1
        FROM perseus_dbo.vw_material_transition_material_up AS mtm
        JOIN perseus_dbo.fatsmurf AS fs
            ON fs.uid = mtm.transition_uid
        JOIN upstream AS r
            ON r.source_uid = mtm.destination_uid AND fs.smurf_id IN (110, 111, 365))
    SELECT
        transition_uid
        INTO var_sample_uid
        FROM upstream
        WHERE transition_type_id = 365
        ORDER BY level ASC NULLS FIRST
        LIMIT 1;

    IF var_sample_uid IS NOT NULL THEN
        SELECT
            CAST (aws_sqlserver_ext.datediff('hour', (SELECT
                transition.run_on
                FROM perseus_dbo.fatsmurf AS transition
                WHERE uid = var_fermentation_uid)::TIMESTAMP, (SELECT
                transition.run_on
                FROM perseus_dbo.fatsmurf AS transition
                WHERE uid = var_sample_uid)::TIMESTAMP) AS DOUBLE PRECISION)
            INTO var_result
            FROM perseus_dbo.goo AS material
            WHERE material.uid = var_material_uid;
    ELSE
        SELECT
            CAST (aws_sqlserver_ext.datediff('hour', (SELECT
                transition.run_on
                FROM perseus_dbo.fatsmurf AS transition
                WHERE uid = var_fermentation_uid)::TIMESTAMP, material.added_on::TIMESTAMP) AS DOUBLE PRECISION)
            INTO var_result
            FROM perseus_dbo.goo AS material
            WHERE material.uid = var_material_uid;
    END IF;
    RETURN var_result;
END;
$BODY$
LANGUAGE  plpgsql;

