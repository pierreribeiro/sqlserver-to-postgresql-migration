CREATE OR REPLACE  VIEW perseus_dbo.combined_sp_field_map (id, field_map_block_id, name, description, display_order, setter, lookup, lookup_service, nullable, field_map_type_id, database_id, save_sequence, onchange, field_map_set_id) AS
SELECT
    sp.id + 20000 AS id, sp.smurf_id + 1000 AS field_map_block_id, p.name ||
    CASE
        WHEN u.name IS NOT NULL THEN ' (' || u.name || ')'
        ELSE ''
    END AS name, CAST (NULL AS VARCHAR(50)) AS description, sp.sort_order AS display_order, 'setPollValueBySpid(' || CAST (sp.id AS VARCHAR(25)) || ', ?)' AS setter,
    CASE
        WHEN po.property_id IS NULL THEN NULL
        ELSE 'PropertyPeer::getLookupByPropertyId(' || CAST (po.property_id AS VARCHAR(10)) || ')'
    END AS lookup, CAST (NULL AS VARCHAR(50)) AS lookup_service, 1 AS nullable,
    CASE
        WHEN po.property_id IS NOT NULL THEN 12
        ELSE 10
    END AS field_map_type_id, CAST (NULL AS VARCHAR(50)) AS database_id, 1 AS save_sequence, CAST (NULL AS VARCHAR(50)) AS onchange,
    CASE
        WHEN s.class_id = 2 THEN 9
        ELSE 12
    END AS field_map_set_id
    FROM perseus_dbo.smurf_property AS sp
    JOIN perseus_dbo.smurf AS s
        ON sp.smurf_id = s.id
    JOIN perseus_dbo.property AS p
        ON sp.property_id = p.id
    LEFT OUTER JOIN perseus_dbo.unit AS u
        ON u.id = p.unit_id
    LEFT OUTER JOIN perseus_dbo.property_option AS po
        ON po.property_id = p.id
UNION
/* fatsmurfs for list and csv */
SELECT
    sp.id + 30000 AS id, sp.smurf_id + 2000 AS field_map_block_id, p.name ||
    CASE
        WHEN u.name IS NOT NULL THEN ' (' || u.name || ')'
        ELSE ''
    END AS name, CAST (NULL AS VARCHAR(50)) AS description, sp.sort_order AS display_order, NULL AS setter, NULL AS lookup, CAST (NULL AS VARCHAR(50)) AS lookup_service, 1 AS nullable,
    CASE
        WHEN po.property_id IS NOT NULL THEN 12
        ELSE 10
    END AS field_map_type_id, CAST (NULL AS VARCHAR(50)) AS database_id, 2 AS save_sequence, CAST (NULL AS VARCHAR(50)) AS onchange,
    CASE
        WHEN s.class_id = 2 THEN 9
        ELSE 12
    END
    FROM perseus_dbo.smurf_property AS sp
    JOIN perseus_dbo.smurf AS s
        ON sp.smurf_id = s.id
    JOIN perseus_dbo.property AS p
        ON sp.property_id = p.id
    LEFT OUTER JOIN perseus_dbo.unit AS u
        ON u.id = p.unit_id
    LEFT OUTER JOIN perseus_dbo.property_option AS po
        ON po.property_id = p.id
UNION
/* fatsmurfs for single reading editing */
SELECT
    sp.id + 40000 AS id, sp.smurf_id + 3000 AS field_map_block_id, p.name ||
    CASE
        WHEN u.name IS NOT NULL THEN ' (' || u.name || ')'
        ELSE ''
    END AS name, CAST (NULL AS VARCHAR(50)) AS description, sp.sort_order AS display_order, 'setPollValueBySpid(' || CAST (sp.id AS VARCHAR(25)) || ', ?)' AS setter,
    CASE
        WHEN po.property_id IS NULL THEN NULL
        ELSE 'PropertyPeer::getLookupByPropertyId(' || CAST (po.property_id AS VARCHAR(10)) || ')'
    END AS lookup, CAST (NULL AS VARCHAR(50)) AS lookup_service, 1 AS nullable,
    CASE
        WHEN po.property_id IS NOT NULL THEN 12
        ELSE 10
    END AS field_map_type_id, CAST (NULL AS VARCHAR(50)) AS database_id, 2 AS save_sequence, CAST (NULL AS VARCHAR(50)) AS onchange,
    CASE
        WHEN s.class_id = 2 THEN 9
        ELSE 12
    END
    FROM perseus_dbo.smurf_property AS sp
    JOIN perseus_dbo.smurf AS s
        ON sp.smurf_id = s.id
    JOIN perseus_dbo.property AS p
        ON sp.property_id = p.id
    LEFT OUTER JOIN perseus_dbo.unit AS u
        ON u.id = p.unit_id
    LEFT OUTER JOIN perseus_dbo.property_option AS po
        ON po.property_id = p.id
/* all fatsmurf reading */
;

