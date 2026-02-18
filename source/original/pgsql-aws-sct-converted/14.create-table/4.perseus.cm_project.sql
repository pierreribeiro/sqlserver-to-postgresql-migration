CREATE TABLE perseus_dbo.cm_project(
    project_id SMALLINT NOT NULL,
    label CITEXT NOT NULL,
    is_active NUMERIC(1,0) NOT NULL,
    display_order SMALLINT NOT NULL,
    group_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

