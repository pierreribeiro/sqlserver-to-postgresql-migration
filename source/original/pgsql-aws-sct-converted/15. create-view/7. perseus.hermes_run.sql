CREATE OR REPLACE  VIEW perseus_dbo.hermes_run (experiment_id, run_id, description, created_on, strain, yield, titer, result_goo_id, feedstock_goo_id, container_id, run_on, duration) AS
SELECT
    r.experiment_id, r.local_id AS run_id, r.description, r.created_on, r.strain, r.max_yield AS yield, r.max_titer AS titer, rg.id AS result_goo_id, ig.id AS feedstock_goo_id, c.id AS container_id, r.start_time AS run_on, r.stop_time AS duration
    FROM perseus_hermes.run AS r
    LEFT OUTER JOIN perseus_dbo.goo AS rg
        ON ('m' || CAST (rg.id AS VARCHAR(10)))::CITEXT = r.resultant_material
    LEFT OUTER JOIN perseus_dbo.goo AS ig
        ON ('m' || CAST (ig.id AS VARCHAR(10)))::CITEXT = r.feedstock_material
    LEFT OUTER JOIN perseus_dbo.container AS c
        ON c.uid = r.tank
    WHERE (COALESCE(r.feedstock_material, '')::CITEXT != '' OR COALESCE(r.resultant_material, '')::CITEXT != '') AND COALESCE(r.feedstock_material, '')::CITEXT != COALESCE(r.resultant_material, '')::CITEXT;

