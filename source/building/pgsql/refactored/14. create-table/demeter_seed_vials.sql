-- Foreign Table: demeter.seed_vials
-- Source: SQL Server [demeter].[seed_vials]
-- Columns: 22
-- FDW Server: demeter_server

CREATE FOREIGN TABLE IF NOT EXISTS demeter.seed_vials (
    id INTEGER NOT NULL,
    strain VARCHAR(30) NOT NULL,
    clone_id VARCHAR(20),
    end_date DATE,
    nat_plating_seedvial VARCHAR(10),
    nat_plating_48hr_od VARCHAR(10),
    contamination_testing_notes VARCHAR(250),
    nr_to_historical NUMERIC(10,2),
    pa_to_historical NUMERIC(10,2),
    jet_to_historical NUMERIC(10,2),
    project VARCHAR(30),
    growth_media VARCHAR(50),
    antibioticos_inventory INTEGER,
    campinas_inventory INTEGER,
    tandl_inventory INTEGER,
    viability_pre_na VARCHAR(5),
    ssod_to_historical_na VARCHAR(5),
    uv_fene_to_historical_na VARCHAR(5),
    nr_to_historical_na VARCHAR(5),
    pa_to_historical_na VARCHAR(5),
    jet_to_historical_na VARCHAR(5),
    uv_fene_to_historical NUMERIC(10,2)
) SERVER demeter_server
OPTIONS (schema_name 'demeter', table_name 'seed_vials');
