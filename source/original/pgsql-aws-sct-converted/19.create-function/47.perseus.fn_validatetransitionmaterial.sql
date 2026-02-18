CREATE OR REPLACE FUNCTION perseus_dbo.fn_validatetransitionmaterial()
RETURNS trigger
AS
$BODY$
BEGIN
    IF (SELECT
        COUNT(*)
        FROM inserted AS ins
        JOIN perseus_dbo.transition_material AS tm
            ON ins.material_id = tm.material_id
        WHERE tm.transition_id != ins.transition_id) > 0 THEN
        RAISE 'Error %, severity %, state % was raised. Message: %.', '50000', 16, 1, 'A material cannot be the output of more than 1 process.' USING ERRCODE = '50000';
        RETURN NULL;
    END IF;
    RETURN NULL;
END;
$BODY$
LANGUAGE  plpgsql;

