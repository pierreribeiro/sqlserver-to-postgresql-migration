CREATE TABLE perseus_demeter.seed_vials(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    strain CITEXT NOT NULL,
    clone_id CITEXT,
    end_date DATE,
    nat_plating_seedvial CITEXT,
    nat_plating_48hr_od CITEXT,
    contamination_testing_notes CITEXT,
    nr_to_historical NUMERIC(10,2),
    pa_to_historical NUMERIC(10,2),
    jet_to_historical NUMERIC(10,2),
    project CITEXT,
    growth_media CITEXT,
    antibioticos_inventory INTEGER,
    campinas_inventory INTEGER,
    tandl_inventory INTEGER,
    viability_pre_na CITEXT,
    ssod_to_historical_na CITEXT,
    uv_fene_to_historical_na CITEXT,
    nr_to_historical_na CITEXT,
    pa_to_historical_na CITEXT,
    jet_to_historical_na CITEXT,
    uv_fene_to_historical NUMERIC(10,2)
)
        WITH (
        OIDS=FALSE
        );

