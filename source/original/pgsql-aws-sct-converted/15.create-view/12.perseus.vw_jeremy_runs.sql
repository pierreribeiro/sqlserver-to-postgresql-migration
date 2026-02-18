CREATE OR REPLACE  VIEW perseus_dbo.vw_jeremy_runs (experiment, run, run_label, vessel_size, feedstock_type, strain, name, description, cell_harvest_id, liquid_separation_id) AS
WITH RECURSIVE tree
AS (
/* Anchor member definition */
SELECT
    g.id AS starting_point, NULL AS parent, g.id AS child
    FROM perseus_dbo.goo AS g
    JOIN perseus_hermes.run AS r
        ON r.resultant_material = g.uid
UNION ALL
/* Recursive member definition */
SELECT
    r.starting_point, g.id, c.id AS child
    FROM perseus_dbo.goo AS g
    JOIN perseus_dbo.goo AS c
        ON c.tree_scope_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_scope_key
        */
        = g.tree_scope_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_scope_key
        */
        AND c.tree_left_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_left_key
        */
        > g.tree_left_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_left_key
        */
        AND c.tree_right_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_right_key
        */
        < g.tree_right_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_right_key
        */
    JOIN tree AS r
        ON g.id = r.child
UNION ALL
SELECT
    r.starting_point, gr.parent, gr.child AS child
    FROM perseus_dbo.goo AS g
    JOIN perseus_dbo.goo_relationship AS gr
        ON g.id = gr.parent
    JOIN tree AS r
        ON gr.parent = r.child)
SELECT
    *
    FROM (SELECT
        r.experiment_id AS experiment, r.local_id AS run, r.description AS run_label, rcv.value AS vessel_size, gt.name AS feedstock_type, r.strain, g.name, g.description, MIN(cs.id) AS cell_harvest_id, MIN(ls.id) AS liquid_separation_id
        FROM perseus_hermes.run AS r
        JOIN perseus_dbo.goo AS g
            ON r.resultant_material = g.uid
        JOIN tree AS t
            ON g.id = t.starting_point
        LEFT OUTER JOIN perseus_hermes.run_condition_value AS rcv
            ON rcv.run_id = r.id AND rcv.master_condition_id = 65
        LEFT OUTER JOIN perseus_dbo.goo AS i
            ON i.uid = r.feedstock_material
        LEFT OUTER JOIN perseus_dbo.goo_type AS gt
            ON gt.id = i.goo_type_id
        LEFT OUTER JOIN perseus_dbo.fatsmurf AS cs
            ON t.child = cs.goo_id
            /*
            [9997 - Severity HIGH - Unable to resolve the object goo_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            goo_id
            */
            AND cs.smurf_id = 23
        LEFT OUTER JOIN perseus_dbo.fatsmurf AS ls
            ON t.child = ls.goo_id
            /*
            [9997 - Severity HIGH - Unable to resolve the object goo_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            goo_id
            */
            AND ls.smurf_id = 25
        GROUP BY r.experiment_id, r.local_id, gt.name, r.strain, g.name, g.description, r.description, rcv.value) AS d
    WHERE cell_harvest_id IS NOT NULL OR liquid_separation_id IS NOT NULL;

