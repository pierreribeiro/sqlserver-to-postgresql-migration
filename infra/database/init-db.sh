#!/usr/bin/env bash
#
# Perseus Database Migration - PostgreSQL Container Initialization Script
#
# This script manages the PostgreSQL Docker container lifecycle for
# the Perseus database migration project.
#
# Usage:
#   ./init-db.sh [command]
#
# Commands:
#   setup     - Initial setup (create password file)
#   start     - Start PostgreSQL container
#   stop      - Stop PostgreSQL container
#   restart   - Restart PostgreSQL container
#   logs      - View container logs
#   shell     - Connect to PostgreSQL shell (psql)
#   status    - Show container status
#   clean     - Remove container and volumes (DESTRUCTIVE)
#   help      - Show this help message
#

# Future Enhancements Backlog Section
# 1. Create an env.conf file for setting up script initial variables
# 2. Execution logs must be written in the global temporary directory informed in configuration file.
# 3. Directory logs tree pattern: {global_dir}/{branch_name}/{dir_script_souce}/file_name_{timestamp}.log


set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Configuration
# Note: Mannually commented by Pierre at 11-02-2026
# Enhancement: Consider moving these configurations to a separate config file (e.g., config.env and secrets in .secrets dir) for better maintainability and security. 
# This would allow us to keep sensitive information like passwords out of the script and make it easier to update configurations without modifying the script code. 
#COMPOSE_FILE="${SCRIPT_DIR}/compose.yaml"
#SECRETS_DIR="${SCRIPT_DIR}/.secrets"
#PASSWORD_FILE="${SECRETS_DIR}/postgres_password.txt"
#PGDATA_DIR="${SCRIPT_DIR}/pgdata"

# Configuration
COMPOSE_FILE="${SCRIPT_DIR}/compose.yaml"
SECRETS_DIR="/Users/pierre.ribeiro/workspace/sharing/sqlserver-to-postgresql-migration/perseus-database/.secrets"
PASSWORD_FILE="${SECRETS_DIR}/postgres_password.txt"
PGDATA_DIR="/Users/pierre.ribeiro/workspace/sharing/sqlserver-to-postgresql-migration/perseus-database/pg_data"

# Database connection parameters
DB_USER="perseus_admin"
DB_NAME="perseus_dev"
DB_HOST="localhost"
DB_PORT="5432"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Setup function - creates password file if it doesn't exist
setup() {
    log_info "Setting up PostgreSQL development environment..."

    # Create secrets directory if it doesn't exist
    if [[ ! -d "${SECRETS_DIR}" ]]; then
        mkdir -p "${SECRETS_DIR}"
        log_info "Created secrets directory: ${SECRETS_DIR}"
    fi

    # Create password file if it doesn't exist
    if [[ ! -f "${PASSWORD_FILE}" ]]; then
        # Generate a secure random password
        GENERATED_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        echo -n "${GENERATED_PASSWORD}" > "${PASSWORD_FILE}"
        chmod 600 "${PASSWORD_FILE}"
        log_success "Generated PostgreSQL password and saved to ${PASSWORD_FILE}"
        log_warning "IMPORTANT: The new password is in ${PASSWORD_FILE}. Keep this file secure."
    else
        log_info "Password file already exists: ${PASSWORD_FILE}"
    fi

    # Create pgdata directory if it doesn't exist
    if [[ ! -d "${PGDATA_DIR}" ]]; then
        mkdir -p "${PGDATA_DIR}"
        log_info "Created data directory: ${PGDATA_DIR}"
    fi

    # Create init-scripts directory if it doesn't exist
    if [[ ! -d "${SCRIPT_DIR}/init-scripts" ]]; then
        mkdir -p "${SCRIPT_DIR}/init-scripts"
        log_info "Created init-scripts directory"
    fi

    log_success "Setup completed successfully!"
    log_info "Next steps:"
    log_info "  1. Run './init-db.sh start' to start the PostgreSQL container"
    log_info "  2. Run './init-db.sh shell' to connect to the database"
}

# Start PostgreSQL container
start() {
    log_info "Starting PostgreSQL container..."

    # Check if password file exists
    if [[ ! -f "${PASSWORD_FILE}" ]]; then
        log_error "Password file not found. Run './init-db.sh setup' first."
        exit 1
    fi

    # Start container using Docker Compose
    cd "${SCRIPT_DIR}"
    docker compose -f "${COMPOSE_FILE}" up -d

    log_success "PostgreSQL container started successfully!"
    log_info "Connection details:"
    log_info "  Host:     ${DB_HOST}"
    log_info "  Port:     ${DB_PORT}"
    log_info "  Database: ${DB_NAME}"
    log_info "  User:     ${DB_USER}"
    log_info "  Password: (stored in ${PASSWORD_FILE})"
    log_info ""
    log_info "Use './init-db.sh shell' to connect to the database"
}

# Stop PostgreSQL container
stop() {
    log_info "Stopping PostgreSQL container..."
    cd "${SCRIPT_DIR}"
    docker compose -f "${COMPOSE_FILE}" down
    log_success "PostgreSQL container stopped successfully!"
}

# Restart PostgreSQL container
restart() {
    log_info "Restarting PostgreSQL container..."
    stop
    start
}

# View container logs
logs() {
    log_info "Showing PostgreSQL container logs (Ctrl+C to exit)..."
    cd "${SCRIPT_DIR}"
    docker compose -f "${COMPOSE_FILE}" logs -f postgres
}

# Connect to PostgreSQL shell
shell() {
    if [[ ! -f "${PASSWORD_FILE}" ]]; then
        log_error "Password file not found. Run './init-db.sh setup' first."
        exit 1
    fi

    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^perseus-postgres-dev$"; then
        log_error "PostgreSQL container is not running. Run './init-db.sh start' first."
        exit 1
    fi

    log_info "Connecting to PostgreSQL shell..."
    docker exec -it perseus-postgres-dev psql -U "${DB_USER}" -d "${DB_NAME}"
}

# Show container status
status() {
    log_info "PostgreSQL container status:"
    cd "${SCRIPT_DIR}"
    docker compose -f "${COMPOSE_FILE}" ps

    if docker ps --format '{{.Names}}' | grep -q "^perseus-postgres-dev$"; then
        log_info ""
        log_success "Container is running"

        # Show connection string
        log_info ""
        log_info "Connection string:"
        log_info "  postgresql://${DB_USER}:******@${DB_HOST}:${DB_PORT}/${DB_NAME}"
        log_info "Password file: ${PASSWORD_FILE}"
    else
        log_warning "Container is not running"
    fi
}

# Clean up (remove container and volumes)
clean() {
    log_warning "This will DESTROY all data in the PostgreSQL container and volumes!"
    read -p "Are you sure? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi

    log_info "Removing PostgreSQL container and volumes..."
    cd "${SCRIPT_DIR}"
    docker compose -f "${COMPOSE_FILE}" down -v

    # Remove pgdata directory
    if [[ -d "${PGDATA_DIR}" ]]; then
        rm -rf "${PGDATA_DIR}"
        log_info "Removed data directory: ${PGDATA_DIR}"
    fi

    log_success "Cleanup completed successfully!"
    log_info "Run './init-db.sh setup' to reinitialize"
}

# Show help
show_help() {
    cat << EOF
Perseus Database Migration - PostgreSQL Container Management

Usage: $0 [command]

Commands:
  setup     Initial setup (create password file and directories)
  start     Start PostgreSQL container
  stop      Stop PostgreSQL container
  restart   Restart PostgreSQL container
  logs      View container logs (follow mode)
  shell     Connect to PostgreSQL shell (psql)
  status    Show container status and connection info
  clean     Remove container and volumes (DESTRUCTIVE)
  help      Show this help message

Examples:
  # Initial setup
  $0 setup

  # Start the database
  $0 start

  # Connect to database
  $0 shell

  # View logs
  $0 logs

  # Check status
  $0 status

For more information, see: infra/database/README.md
EOF
}

# Main script logic
main() {
    case "${1:-help}" in
        setup)
            setup
            ;;
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        logs)
            logs
            ;;
        shell)
            shell
            ;;
        status)
            status
            ;;
        clean)
            clean
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
