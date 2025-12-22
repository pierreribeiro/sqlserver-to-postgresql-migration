CREATE TABLE perseus_dbo.m_upstream(
    start_point CITEXT NOT NULL,
    end_point CITEXT NOT NULL,
    path CITEXT NOT NULL,
    level INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

