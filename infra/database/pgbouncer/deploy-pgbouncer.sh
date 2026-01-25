#!/usr/bin/env bash
# PgBouncer Deployment Script
# Builds and starts PgBouncer container
#
# Usage: ./deploy-pgbouncer.sh

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE_DIR="$(dirname "${SCRIPT_DIR}")"

echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${BLUE}  PgBouncer Deployment - Perseus PostgreSQL Migration${NC}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════${NC}\n"

# Step 1: Verify prerequisites
echo -e "${BLUE}[1/5]${NC} Checking prerequisites..."

# Check if PostgreSQL is running
if ! docker ps | grep -q "perseus-postgres-dev"; then
    echo -e "${RED}✗ Error: PostgreSQL container is not running${NC}"
    echo -e "${YELLOW}Start PostgreSQL first:${NC}"
    echo -e "  cd ${DATABASE_DIR}"
    echo -e "  docker-compose up -d postgres"
    exit 1
fi
echo -e "${GREEN}✓${NC} PostgreSQL container is running"

# Check if userlist.txt exists and has correct permissions
if [ ! -f "${SCRIPT_DIR}/userlist.txt" ]; then
    echo -e "${RED}✗ Error: userlist.txt not found${NC}"
    echo -e "${YELLOW}Generate it first:${NC}"
    echo -e "  cd ${SCRIPT_DIR}"
    echo -e "  ./generate-userlist.sh"
    exit 1
fi

PERMS=$(stat -f "%Lp" "${SCRIPT_DIR}/userlist.txt" 2>/dev/null || stat -c "%a" "${SCRIPT_DIR}/userlist.txt" 2>/dev/null)
if [ "$PERMS" != "600" ]; then
    echo -e "${YELLOW}⚠ Fixing userlist.txt permissions...${NC}"
    chmod 600 "${SCRIPT_DIR}/userlist.txt"
fi
echo -e "${GREEN}✓${NC} userlist.txt exists with correct permissions (600)"

# Step 2: Build PgBouncer image
echo -e "\n${BLUE}[2/5]${NC} Building PgBouncer Docker image..."
cd "${DATABASE_DIR}"
if docker-compose build pgbouncer; then
    echo -e "${GREEN}✓${NC} PgBouncer image built successfully"
else
    echo -e "${RED}✗ Error: Failed to build PgBouncer image${NC}"
    exit 1
fi

# Step 3: Stop existing PgBouncer container (if running)
echo -e "\n${BLUE}[3/5]${NC} Checking for existing PgBouncer container..."
if docker ps -a | grep -q "perseus-pgbouncer-dev"; then
    echo -e "${YELLOW}⚠ Stopping existing PgBouncer container...${NC}"
    docker-compose stop pgbouncer
    docker-compose rm -f pgbouncer
    echo -e "${GREEN}✓${NC} Existing container stopped and removed"
else
    echo -e "${GREEN}✓${NC} No existing container found"
fi

# Step 4: Start PgBouncer
echo -e "\n${BLUE}[4/5]${NC} Starting PgBouncer container..."
if docker-compose up -d pgbouncer; then
    echo -e "${GREEN}✓${NC} PgBouncer container started"
else
    echo -e "${RED}✗ Error: Failed to start PgBouncer${NC}"
    echo -e "\n${YELLOW}Check logs:${NC}"
    echo -e "  docker-compose logs pgbouncer"
    exit 1
fi

# Wait for container to be healthy
echo -e "\n${BLUE}[5/5]${NC} Waiting for PgBouncer to be ready..."
RETRY_COUNT=0
MAX_RETRIES=30
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker ps | grep "perseus-pgbouncer-dev" | grep -q "(healthy)"; then
        echo -e "${GREEN}✓${NC} PgBouncer is healthy and ready"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo -ne "${YELLOW}.${NC}"
    sleep 1
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "\n${RED}✗ Error: PgBouncer did not become healthy within 30 seconds${NC}"
    echo -e "\n${YELLOW}Check logs:${NC}"
    docker-compose logs pgbouncer
    exit 1
fi

# Step 5: Verify deployment
echo -e "\n${BOLD}${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Deployment Complete!${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════════${NC}\n"

# Show connection information
echo -e "${BLUE}Connection Information:${NC}"
echo -e "  ${BOLD}Host:${NC}     localhost"
echo -e "  ${BOLD}Port:${NC}     6432 (PgBouncer)"
echo -e "  ${BOLD}Database:${NC} perseus_dev"
echo -e "  ${BOLD}User:${NC}     perseus_admin"
echo ""
echo -e "${BLUE}Test connection:${NC}"
echo -e "  psql -h localhost -p 6432 -U perseus_admin -d perseus_dev"
echo ""
echo -e "${BLUE}View pool status:${NC}"
echo -e "  psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c \"SHOW POOLS;\""
echo ""
echo -e "${BLUE}Run comprehensive tests:${NC}"
echo -e "  cd ${SCRIPT_DIR}"
echo -e "  ./test-pgbouncer.sh"
echo ""
echo -e "${BLUE}Monitor in real-time:${NC}"
echo -e "  cd ${SCRIPT_DIR}"
echo -e "  ./monitor-pgbouncer.sh 5"
echo ""

# Show container status
echo -e "${BLUE}Container Status:${NC}"
docker ps --filter "name=perseus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Quick health check
echo -e "${BLUE}Quick Health Check:${NC}"
if psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW POOLS;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PgBouncer is accessible"
    psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW POOLS;"
else
    echo -e "${RED}✗${NC} Cannot connect to PgBouncer"
    echo -e "\n${YELLOW}Troubleshooting:${NC}"
    echo -e "  1. Check container logs: docker-compose logs pgbouncer"
    echo -e "  2. Verify userlist.txt: cat ${SCRIPT_DIR}/userlist.txt"
    echo -e "  3. Check PostgreSQL: psql -h localhost -p 5432 -U perseus_admin -d perseus_dev"
fi

echo ""
