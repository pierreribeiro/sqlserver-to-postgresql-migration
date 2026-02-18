-- Table: perseus.recipe
-- Source: SQL Server [dbo].[recipe]
-- Columns: 16

CREATE TABLE IF NOT EXISTS perseus.recipe (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(200) NOT NULL,
    goo_type_id INTEGER NOT NULL,
    description TEXT,
    sop TEXT,
    workflow_id INTEGER,
    added_by INTEGER NOT NULL,
    added_on TIMESTAMPTZ NOT NULL,
    is_preferred BOOLEAN NOT NULL DEFAULT FALSE,
    qc BOOLEAN NOT NULL DEFAULT FALSE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    feed_type_id INTEGER,
    stock_concentration DOUBLE PRECISION,
    sterilization_method VARCHAR(100),
    inoculant_percent DOUBLE PRECISION,
    post_inoc_volume_ml DOUBLE PRECISION
);
