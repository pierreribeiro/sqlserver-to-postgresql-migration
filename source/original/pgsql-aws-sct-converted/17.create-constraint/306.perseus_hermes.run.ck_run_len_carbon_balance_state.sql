ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_carbon_balance_state CHECK (length(carbon_balance_state::text) <= 4000);

