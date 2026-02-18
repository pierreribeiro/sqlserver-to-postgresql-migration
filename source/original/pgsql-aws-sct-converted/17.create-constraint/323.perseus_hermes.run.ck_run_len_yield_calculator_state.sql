ALTER TABLE perseus_hermes.run
ADD CONSTRAINT ck_run_len_yield_calculator_state CHECK (length(yield_calculator_state::text) <= 4000);

