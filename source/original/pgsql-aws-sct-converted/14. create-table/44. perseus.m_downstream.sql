CREATE TABLE perseus_dbo.m_downstream(
    start_point CITEXT NOT NULL,
    end_point CITEXT NOT NULL,
    path CITEXT NOT NULL,
    level INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

