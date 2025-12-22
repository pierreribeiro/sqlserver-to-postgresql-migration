CREATE OR REPLACE  VIEW perseus_dbo.combined_sp_field_map_display_type (id, field_map_id, display_type_id, display, display_layout_id, manditory) AS
SELECT
    sp.id + 10000 + dl.id AS id, sp.id + 20000 AS field_map_id, dl.id AS display_type_id, 'getPollValueBySmurfPropertyId(' || CAST (sp.id AS VARCHAR(25)) || ')' AS display, 5 AS display_layout_id, 0 AS manditory
    FROM perseus_dbo.smurf_property AS sp
    JOIN perseus_dbo.smurf AS s
        ON s.id = sp.smurf_id
    JOIN perseus_dbo.property AS p
        ON p.id = sp.property_id
    CROSS JOIN perseus_dbo.display_layout AS dl
    WHERE sp.disabled = 0 AND dl.id IN (1)
UNION
/* fatsmurf reading table */
SELECT
    sp.id + 20000 + dl.id AS id, sp.id + 20000 AS field_map_id, dl.id AS display_type_id, 'getPollValueBySmurfPropertyId(' || CAST (sp.id AS VARCHAR(25)) || ')' AS display, 7 AS display_layout_id, 0 AS manditory
    FROM perseus_dbo.smurf_property AS sp
    JOIN perseus_dbo.smurf AS s
        ON s.id = sp.smurf_id
    JOIN perseus_dbo.property AS p
        ON p.id = sp.property_id
    CROSS JOIN perseus_dbo.display_layout AS dl
    WHERE sp.disabled = 0 AND dl.id IN (7)
UNION
/* fatsmurf listing */
SELECT
    sp.id + 30000 + dl.id AS id, sp.id + 30000 AS field_map_id, dl.id AS display_type_id, 'getPollValueStringBySmurfPropertyId(' || CAST (sp.id AS VARCHAR(25)) || ')' AS display, 7 AS display_layout_id, 0 AS manditory
    FROM perseus_dbo.smurf_property AS sp
    JOIN perseus_dbo.smurf AS s
        ON s.id = sp.smurf_id
    JOIN perseus_dbo.property AS p
        ON p.id = sp.property_id
    CROSS JOIN perseus_dbo.display_layout AS dl
    WHERE sp.disabled = 0 AND dl.id IN (3)
UNION
/* fatsmurf csv */
SELECT
    sp.id + 40000 + dl.id AS id, sp.id + 30000 AS field_map_id, dl.id AS display_type_id, 'getPollValueStringBySmurfPropertyId(' || CAST (sp.id AS VARCHAR(25)) || ')' AS display, 7 AS display_layout_id, 0 AS manditory
    FROM perseus_dbo.smurf_property AS sp
    JOIN perseus_dbo.smurf AS s
        ON s.id = sp.smurf_id
    JOIN perseus_dbo.property AS p
        ON p.id = sp.property_id
    CROSS JOIN perseus_dbo.display_layout AS dl
    WHERE sp.disabled = 0 AND dl.id IN (6)
UNION
/* fatsmurf single reading editing */
SELECT
    sp.id + 50000 + dl.id AS id, sp.id + 40000 AS field_map_id, dl.id AS display_type_id, 'getPollValueBySmurfPropertyId(' || CAST (sp.id AS VARCHAR(25)) || ')' AS display, 5 AS display_layout_id, 0 AS manditory
    FROM perseus_dbo.smurf_property AS sp
    JOIN perseus_dbo.smurf AS s
        ON s.id = sp.smurf_id
    JOIN perseus_dbo.property AS p
        ON p.id = sp.property_id
    CROSS JOIN perseus_dbo.display_layout AS dl
    WHERE sp.disabled = 0 AND dl.id IN (1)
/* fatsmurf reading editing */
;

