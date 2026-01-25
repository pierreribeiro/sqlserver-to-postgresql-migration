# PgBouncer Dockerfile for Perseus PostgreSQL Connection Pooling
# Based on official PgBouncer Alpine image for minimal footprint
# Production-ready configuration for development environment

FROM pgbouncer/pgbouncer:1.22.1

# Install additional utilities for monitoring and troubleshooting
USER root
RUN apk add --no-cache \
    postgresql-client \
    ca-certificates \
    bash \
    curl

# Create directories for PgBouncer configuration
RUN mkdir -p /etc/pgbouncer /var/log/pgbouncer && \
    chown -R pgbouncer:pgbouncer /etc/pgbouncer /var/log/pgbouncer

# Copy configuration files
COPY pgbouncer.ini /etc/pgbouncer/pgbouncer.ini
COPY userlist.txt /etc/pgbouncer/userlist.txt

# Set correct permissions
RUN chmod 600 /etc/pgbouncer/userlist.txt && \
    chown pgbouncer:pgbouncer /etc/pgbouncer/userlist.txt /etc/pgbouncer/pgbouncer.ini

# Switch to pgbouncer user for security
USER pgbouncer

# Expose PgBouncer port (6432)
EXPOSE 6432

# Health check - verify PgBouncer is responding
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD psql -h localhost -p 6432 -U pgbouncer -d pgbouncer -c "SHOW POOLS;" || exit 1

# Start PgBouncer with configuration file
CMD ["/usr/bin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]
