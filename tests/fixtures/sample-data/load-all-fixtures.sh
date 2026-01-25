#!/usr/bin/env bash
# =============================================================================
# Load All Test Fixtures
# =============================================================================
# Purpose: Load all sample data fixtures in dependency order
# Usage: ./load-all-fixtures.sh [dev|staging|prod]
# =============================================================================

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Configuration
ENV="${1:-dev}"
DOCKER_CONTAINER="perseus-postgres-dev"
DB_NAME="perseus_${ENV}"
DB_USER="perseus_admin"

echo -e "${GREEN}=========================================================================${NC}"
echo -e "${GREEN}LOADING TEST FIXTURES${NC}"
echo -e "${GREEN}=========================================================================${NC}"
echo "Environment: ${ENV}"
echo "Database: ${DB_NAME}"
echo ""

# Check if Docker container is running
if ! docker ps --format '{{.Names}}' | grep -q "${DOCKER_CONTAINER}"; then
    echo -e "${RED}[ERROR]${NC} Docker container '${DOCKER_CONTAINER}' is not running"
    exit 1
fi

# Load fixtures in dependency order
FIXTURES=(
    "01-core-tables.sql"
)

for fixture in "${FIXTURES[@]}"; do
    echo -e "${YELLOW}[LOADING]${NC} ${fixture}"

    if docker cp "${fixture}" "${DOCKER_CONTAINER}:/tmp/${fixture}"; then
        if docker exec "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" -f "/tmp/${fixture}" > /dev/null 2>&1; then
            echo -e "${GREEN}[✓ SUCCESS]${NC} ${fixture}"
        else
            echo -e "${RED}[✗ FAILED]${NC} ${fixture}"
            exit 1
        fi
    else
        echo -e "${RED}[✗ ERROR]${NC} Failed to copy ${fixture} to container"
        exit 1
    fi
done

echo ""
echo -e "${GREEN}=========================================================================${NC}"
echo -e "${GREEN}ALL FIXTURES LOADED SUCCESSFULLY${NC}"
echo -e "${GREEN}=========================================================================${NC}"

# Verify fixture load
docker exec "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "
SELECT
    schemaname,
    tablename,
    n_live_tup as row_count
FROM pg_stat_user_tables
WHERE schemaname = 'fixtures'
ORDER BY tablename;
"

exit 0
