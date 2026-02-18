CREATE OR REPLACE PROCEDURE perseus_dbo.usp_updatecontainertypefromargus()
AS 
$BODY$
BEGIN
    /*
    [9996 - Severity CRITICAL - Transformer error occurred in fromClause. Please submit report to developers.]
    UPDATE perseus.dbo.container
    SET container_type_id = 12
    FROM perseus.dbo.container c
    JOIN OPENQUERY(SCAN2, 'select * from scan2.argus.root_plate
                   WHERE plate_format_id = 8 AND hermes_experiment_id IS NOT NULL') rp
    			   ON rp.uid = c.uid AND c.container_type_id != 12;
    [9997 - Severity HIGH - Unable to resolve the object SCAN2. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
     SCAN2
    [9997 - Severity HIGH - Unable to resolve the object uid. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
     uid
    */
    BEGIN
    END;
END;
$BODY$
LANGUAGE plpgsql;

