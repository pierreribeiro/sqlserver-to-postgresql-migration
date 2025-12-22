CREATE OR REPLACE  VIEW perseus_dbo.combined_field_map_block (id, filter, scope) AS
SELECT
    id, filter, scope
    FROM perseus_dbo.field_map_block
UNION
/* All FatSmurf Readings */
SELECT
    id + 1000, 'isSmurf(' || CAST (id AS VARCHAR(10)) || ')', 'FatSmurfReading'
    FROM perseus_dbo.smurf
UNION
/* Fields for fatsmurf list and csv */
SELECT
    id + 2000, 'isSmurf(' || CAST (id AS VARCHAR(10)) || ')', 'FatSmurf'
    FROM perseus_dbo.smurf
UNION
/* for single reading fatsmurf editing */
SELECT
    id + 3000, 'isSmurfWithOneReading(' || CAST (id AS VARCHAR(10)) || ')', 'FatSmurf'
    FROM perseus_dbo.smurf;

