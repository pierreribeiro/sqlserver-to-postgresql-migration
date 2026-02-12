#!/usr/bin/env bash
# Generate PgBouncer userlist.txt from PostgreSQL password hashes
# This script extracts password hashes from PostgreSQL and formats them for PgBouncer
#
# Usage: ./generate-userlist.sh
#
# Prerequisites:
#   - PostgreSQL container must be running
#   - perseus_admin user must exist in PostgreSQL
#   - psql client must be available

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERLIST_FILE="${SCRIPT_DIR}/userlist.txt"
PG_HOST="localhost"
PG_PORT="5432"
PG_USER="perseus_admin"
PG_DB="postgres"

# Users to extract (add more as needed)
USERS=("perseus_admin")

echo -e "${GREEN}PgBouncer Userlist Generator${NC}"
echo "============================================"
echo ""

# Check if PostgreSQL is running
echo -n "Checking PostgreSQL connectivity... "
if ! docker exec perseus-postgres-dev pg_isready -U "${PG_USER}" -d "${PG_DB}" > /dev/null 2>&1; then
    echo -e "${RED}FAILED${NC}"
    echo -e "${RED}Error: PostgreSQL container 'perseus-postgres-dev' is not running or not accessible${NC}"
    echo "Start it with: docker-compose up -d"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Create temporary userlist file
TEMP_FILE=$(mktemp)
trap "rm -f ${TEMP_FILE}" EXIT

# Write header
cat > "${TEMP_FILE}" << EOF
;; PgBouncer User Authentication File
;; Auto-generated on $(date -u +"%Y-%m-%d %H:%M:%S UTC")
;;
;; Format: "username" "password_hash"
;;
;; SECURITY WARNING:
;; This file contains password hashes. Permissions are set to 600 (owner-only).
;; DO NOT commit this file to version control.

EOF

# Extract password hashes for each user
echo ""
echo "Extracting password hashes from PostgreSQL..."
for user in "${USERS[@]}"; do
    echo -n "  - ${user}... "

    # Get password hash from PostgreSQL
    # Using docker exec to run psql inside the container
    HASH=$(docker exec perseus-postgres-dev psql -U "${PG_USER}" -d "${PG_DB}" -tAc \
        "SELECT passwd FROM pg_shadow WHERE usename = '${user}';" 2>/dev/null || echo "")

    if [ -z "${HASH}" ] || [ "${HASH}" = "" ]; then
        echo -e "${YELLOW}NOT FOUND${NC}"
        echo ";; User '${user}' not found in PostgreSQL" >> "${TEMP_FILE}"
        echo "\"${user}\" \"PLACEHOLDER_HASH_NOT_FOUND\"" >> "${TEMP_FILE}"
    else
        echo -e "${GREEN}OK${NC}"
        echo "\"${user}\" \"${HASH}\"" >> "${TEMP_FILE}"
    fi
done

# Add blank line
echo "" >> "${TEMP_FILE}"

# Add stats_user if it doesn't exist (for monitoring)
echo ";; Monitoring user (create manually if needed):" >> "${TEMP_FILE}"
echo ";; CREATE USER stats_user WITH PASSWORD 'secure_password';" >> "${TEMP_FILE}"
echo ";; \"stats_user\" \"PLACEHOLDER_CREATE_USER_FIRST\"" >> "${TEMP_FILE}"

# Move temp file to final location
mv "${TEMP_FILE}" "${USERLIST_FILE}"

# Set secure permissions (owner read/write only)
chmod 600 "${USERLIST_FILE}"

echo ""
echo -e "${GREEN}Success!${NC} Userlist generated at: ${USERLIST_FILE}"
echo ""
echo "File permissions: $(ls -l ${USERLIST_FILE} | awk '{print $1, $3, $4}')"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "  1. Verify the generated hashes in ${USERLIST_FILE}"
echo "  2. Create additional users in PostgreSQL as needed"
echo "  3. Re-run this script after adding new users"
echo "  4. Never commit userlist.txt to version control"
echo ""
