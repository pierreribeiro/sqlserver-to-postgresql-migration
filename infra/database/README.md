# Perseus PostgreSQL Development Environment

Docker-based PostgreSQL 17 development environment for the Perseus database migration project.

## 📋 Overview

This directory contains the configuration for a local PostgreSQL 17 instance used for development and testing during the T-SQL to PostgreSQL migration.

**Key Features:**
- ✅ PostgreSQL 17 (Alpine-based, lightweight)
- ✅ Data persistence via local volume (`./pgdata/`)
- ✅ Secure password management with Docker Secrets
- ✅ UTF-8 encoding and locale compliance (per project spec)
- ✅ Optimized configuration for development workload
- ✅ Accessible from macOS host on port 5432
- ✅ Automated initialization scripts
- ✅ Health checks and logging

## 🚀 Quick Start

### 1. Initial Setup

Run the setup command to create the password file and necessary directories:

```bash
cd infra/database
./init-db.sh setup
```

This will:
- Create the `.secrets/` directory
- Generate a secure random password for PostgreSQL
- Create the `pgdata/` directory for data persistence
- Create the `init-scripts/` directory for initialization SQL

**Important:** The setup command will display the generated password. Save it securely!

### 2. Start PostgreSQL Container

```bash
./init-db.sh start
```

This will:
- Start the PostgreSQL 17 container
- Mount the data volume at `./pgdata/`
- Expose port 5432 on localhost
- Run initialization scripts from `./init-scripts/`

### 3. Connect to Database

Using the management script:

```bash
./init-db.sh shell
```

Or using `psql` directly:

```bash
psql -h localhost -U perseus_admin -d perseus_dev
```

Or using connection string:

```bash
# Get connection string with password
./init-db.sh status

# Example connection string
postgresql://perseus_admin:YOUR_PASSWORD@localhost:5432/perseus_dev
```

## 🛠️ Management Commands

The `init-db.sh` script provides several commands for managing the PostgreSQL container:

| Command | Description |
|---------|-------------|
| `setup` | Initial setup (create password file and directories) |
| `start` | Start PostgreSQL container |
| `stop` | Stop PostgreSQL container |
| `restart` | Restart PostgreSQL container |
| `logs` | View container logs (follow mode) |
| `shell` | Connect to PostgreSQL shell (psql) |
| `status` | Show container status and connection info |
| `clean` | Remove container and volumes (DESTRUCTIVE) |
| `help` | Show help message |

### Examples

```bash
# Start the database
./init-db.sh start

# View logs
./init-db.sh logs

# Check status and get connection string
./init-db.sh status

# Connect to database
./init-db.sh shell

# Restart after configuration changes
./init-db.sh restart

# Stop the database
./init-db.sh stop
```

## 📂 Directory Structure

```
infra/database/
├── compose.yaml              # Docker Compose configuration
├── init-db.sh               # Container management script
├── README.md                # This file
├── .secrets/                # Docker Secrets (gitignored)
│   └── postgres_password.txt
├── pgdata/                  # PostgreSQL data volume (gitignored)
│   ├── base/
│   ├── global/
│   ├── pg_log/
│   └── ...
└── init-scripts/            # SQL initialization scripts
    └── 01-init-database.sql
```

**Note:** The entire `infra/` directory is gitignored to prevent accidental commit of sensitive data and local development artifacts.

## 🔐 Security

### Password Management

- Password is stored in `.secrets/postgres_password.txt`
- File is referenced via Docker Secrets (not exposed as environment variable)
- File permissions set to 600 (owner read/write only)
- Password is gitignored (entire `infra/` directory)

### Connection Security

For production environments, additional security measures should be implemented:
- TLS 1.3 for connections (as per spec: `specs/001-tsql-to-pgsql/spec.md:39`)
- AES-256 encryption at rest
- Network isolation
- Connection pooling via PgBouncer

## 📊 Database Configuration

### Connection Parameters

| Parameter | Value |
|-----------|-------|
| **Host** | localhost |
| **Port** | 5432 |
| **Database** | perseus_dev |
| **User** | perseus_admin |
| **Password** | (stored in `.secrets/postgres_password.txt`) |

### Locale and Encoding

Per project specification (`specs/001-tsql-to-pgsql/spec.md:32`):

- **Encoding:** UTF-8
- **Locale:** en_US.UTF-8
- **LC_ALL:** en_US.UTF-8
- **Timezone:** America/Sao_Paulo

### Performance Tuning

The container is configured with development-optimized settings:

| Setting | Value | Purpose |
|---------|-------|---------|
| `shared_buffers` | 256MB | Memory for caching data |
| `max_connections` | 100 | Concurrent connections |
| `work_mem` | 16MB | Memory per query operation |
| `maintenance_work_mem` | 64MB | Memory for maintenance tasks |
| `effective_cache_size` | 1GB | OS cache estimate |
| `random_page_cost` | 1.1 | SSD optimization |
| `effective_io_concurrency` | 200 | Parallel I/O operations |
| `checkpoint_completion_target` | 0.9 | Spread checkpoint writes |

These settings are optimized for:
- Local SSD storage
- Development workload (not production)
- Typical MacBook Pro/Air specifications

### Logging Configuration

- **Destination:** `./pgdata/pg_log/`
- **Format:** `postgresql-YYYY-MM-DD_HHMMSS.log`
- **Rotation:** Daily or 100MB
- **Logged:** DDL statements, query duration
- **Prefix:** Timestamp, PID, user, database, application, client

## 🔧 Initialization Scripts

SQL scripts in `init-scripts/` run automatically when the container is first created (fresh `pgdata/` volume).

### Included Scripts

1. **01-init-database.sql** - Creates:
   - Required extensions (uuid-ossp, pg_stat_statements, btree_gist, pg_trgm)
   - Schemas (perseus, perseus_test, fixtures)
   - Audit table (perseus.migration_log)
   - Helper functions (perseus.object_exists)

### Adding Custom Initialization

To add custom initialization scripts:

1. Create SQL file in `init-scripts/` with numeric prefix (e.g., `02-my-script.sql`)
2. Scripts execute in alphanumeric order
3. Scripts only run on fresh database (new `pgdata/` volume)

## 🧪 Testing the Setup

After starting the container, verify the setup:

```bash
# Check container status
./init-db.sh status

# Connect to database
./init-db.sh shell

# Inside psql, run verification queries:
\l                          -- List databases
\dn                         -- List schemas
\dx                         -- List extensions
SELECT version();           -- Check PostgreSQL version
SHOW server_encoding;       -- Verify UTF-8
SHOW timezone;              -- Verify timezone
SELECT * FROM perseus.migration_log;  -- Check audit table
```

Expected output:
- PostgreSQL 17.x
- Encoding: UTF8
- Timezone: America/Sao_Paulo
- Schemas: perseus, perseus_test, fixtures, public
- Extensions: uuid-ossp, pg_stat_statements, btree_gist, pg_trgm

## 🔄 Backup and Restore

### Backup

```bash
# Dump entire database
docker exec perseus-postgres-dev pg_dump -U perseus_admin -d perseus_dev > backup.sql

# Dump specific schema
docker exec perseus-postgres-dev pg_dump -U perseus_admin -d perseus_dev -n perseus > perseus_schema_backup.sql

# Dump with data in custom format (compressed)
docker exec perseus-postgres-dev pg_dump -U perseus_admin -d perseus_dev -Fc -f /tmp/perseus.dump
docker cp perseus-postgres-dev:/tmp/perseus.dump ./perseus_backup.dump
```

### Restore

```bash
# Restore from SQL dump
cat backup.sql | docker exec -i perseus-postgres-dev psql -U perseus_admin -d perseus_dev

# Restore from custom format
docker cp ./perseus_backup.dump perseus-postgres-dev:/tmp/perseus.dump
docker exec perseus-postgres-dev pg_restore -U perseus_admin -d perseus_dev /tmp/perseus.dump
```

## 🧹 Maintenance

### View Logs

```bash
# Follow logs in real-time
./init-db.sh logs

# View last 100 lines
docker logs perseus-postgres-dev --tail 100

# View PostgreSQL logs inside container
docker exec perseus-postgres-dev tail -f /var/lib/postgresql/data/pg_log/postgresql-*.log
```

### Clean Restart

To start with a fresh database:

```bash
# WARNING: This destroys all data!
./init-db.sh clean

# Then setup and start again
./init-db.sh setup
./init-db.sh start
```

### Update Container

To update to a newer PostgreSQL 17 image:

```bash
./init-db.sh stop
docker compose pull
./init-db.sh start
```

## 📚 Resources

### Project Documentation

- **Specification:** `specs/001-tsql-to-pgsql/spec.md`
- **Constitution:** `docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md`
- **Project Guide:** `CLAUDE.md`

### PostgreSQL Resources

- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)
- [PostgreSQL on Docker Hub](https://hub.docker.com/_/postgres)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## ⚠️ Troubleshooting

### Container Won't Start

```bash
# Check if port 5432 is already in use
lsof -i :5432

# View container logs
docker logs perseus-postgres-dev

# Check compose configuration
cd infra/database
docker compose config
```

### Permission Denied on pgdata/

```bash
# Reset pgdata permissions
sudo rm -rf ./pgdata
./init-db.sh clean
./init-db.sh setup
./init-db.sh start
```

### Password Not Working

```bash
# Verify password file exists and has correct permissions
ls -la .secrets/postgres_password.txt

# View password (be careful in shared environments)
cat .secrets/postgres_password.txt

# Regenerate password
rm .secrets/postgres_password.txt
./init-db.sh setup
./init-db.sh restart
```

### Can't Connect from Host

```bash
# Verify container is running
docker ps | grep perseus-postgres-dev

# Check port mapping
docker port perseus-postgres-dev

# Test connection
psql -h localhost -U perseus_admin -d perseus_dev -c "SELECT version();"
```

## 📝 Notes

1. **This is a development environment** - Not suitable for production without additional hardening
2. **Data persistence** - Data is stored in `./pgdata/` and survives container restarts
3. **Gitignored** - The entire `infra/` directory is gitignored to prevent accidental commits
4. **Performance** - Settings are optimized for local SSD and typical development workload
5. **Locale** - UTF-8 encoding and en_US.UTF-8 locale per project specification
6. **Migration tracking** - Uses `perseus.migration_log` table for tracking migration progress

---

**Created:** 2026-01-24
**Version:** 1.0
**Project:** Perseus Database Migration (SQL Server → PostgreSQL)
**Contact:** Pierre Ribeiro (Senior DBA/DBRE)
