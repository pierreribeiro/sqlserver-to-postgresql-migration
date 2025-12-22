CREATE OR REPLACE  VIEW perseus_dbo.goo_relationship (parent, child) AS
SELECT
    id AS parent, merged_into
    /*
    [9997 - Severity HIGH - Unable to resolve the object merged_into. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    merged_into
    */
    AS child
    FROM perseus_dbo.goo
    WHERE merged_into
    /*
    [9997 - Severity HIGH - Unable to resolve the object merged_into. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    merged_into
    */
    IS NOT NULL
UNION
SELECT
    p.id, c.id
    FROM perseus_dbo.goo AS p
    JOIN perseus_dbo.fatsmurf AS fs
        ON fs.goo_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object goo_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        goo_id
        */
        = p.id
    JOIN perseus_dbo.goo AS c
        ON c.source_process_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object source_process_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        source_process_id
        */
        = fs.id
UNION
SELECT
    i.id, o.id
    FROM perseus_hermes.run AS r
    JOIN perseus_dbo.goo AS i
        ON i.uid = r.feedstock_material
    JOIN perseus_dbo.goo AS o
        ON o.uid = r.resultant_material
    WHERE COALESCE(r.feedstock_material, '')::CITEXT != COALESCE(r.resultant_material, '')::CITEXT;

