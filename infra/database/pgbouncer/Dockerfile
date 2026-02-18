# PgBouncer Dockerfile for Perseus PostgreSQL Connection Pooling
# Based on official PgBouncer Alpine image for minimal footprint
# Production-ready configuration for development environment

FROM edoburu/pgbouncer:v1.25.1-p0

# Install additional utilities for monitoring and troubleshooting
USER root
#RUN apk add --no-cache \
#    postgresql-client \
#    ca-certificates \
#    bash \
#    curl

# Create pgbouncer user if it doesn't exist
#RUN id -u pgbouncer &>/dev/null || addgroup -S pgbouncer && adduser -S -G pgbouncer pgbouncer

# Create directories for PgBouncer configuration
RUN mkdir -p /var/log/pgbouncer && \
    chmod 755 /var/log/pgbouncer && \
    chown -R postgres:postgres /var/log/pgbouncer

# Copy configuration files
COPY pgbouncer.ini /etc/pgbouncer/pgbouncer.ini
COPY userlist.txt /etc/pgbouncer/userlist.txt

# Set correct permissions
#RUN chmod 600 /etc/pgbouncer/userlist.txt && \
#    chmod 644 /etc/pgbouncer/pgbouncer.ini && \
#    chown pgbouncer:pgbouncer /etc/pgbouncer/userlist.txt /etc/pgbouncer/pgbouncer.ini

# Switch to pgbouncer user for security
#USER pgbouncer
USER postgres

# Expose PgBouncer port (6432)
EXPOSE 6432

# Health check - verify port is listening
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD nc -z localhost 6432 || exit 1

# Override entrypoint to use config file directly
ENTRYPOINT ["/entrypoint.sh"]
# Start PgBouncer with configuration file
#CMD ["/opt/pgbouncer/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]
CMD ["/usr/bin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]