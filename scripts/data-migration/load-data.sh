#!/usr/bin/env bash
#
# Perseus Database Migration - Data Loading Script
# Purpose: Load 15% sample data from SQL Server into PostgreSQL (DEV environment)
# Prerequisites: CSV files exported from SQL Server using extraction scripts
#
# Usage:
#   ./load-data.sh [--validate-only] [--tier N]
#
# Options:
#   --validate-only  Only run validation queries, skip data loading
#   --tier N         Load only specific tier (0-4), default: all tiers
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Configuration
DB_CONTAINER="perseus-postgres-dev"
DB_NAME="perseus_dev"
DB_USER="perseus_admin"
DATA_DIR="${DATA_DIR:-/tmp/perseus-data-export}"
LOG_FILE="${SCRIPT_DIR}/load-data.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Parse command line arguments
VALIDATE_ONLY=false
SPECIFIC_TIER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --validate-only)
            VALIDATE_ONLY=true
            shift
            ;;
        --tier)
            SPECIFIC_TIER="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Initialize log file
echo "=== Perseus Data Migration - $(date) ===" > "$LOG_FILE"

log_info "Starting data migration to DEV environment"
log_info "Data directory: $DATA_DIR"
log_info "Database: $DB_NAME (container: $DB_CONTAINER)"

# Check if database container is running
if ! docker ps | grep -q "$DB_CONTAINER"; then
    log_error "Database container $DB_CONTAINER is not running!"
    exit 1
fi
log_success "Database container is running"

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    log_error "Data directory not found: $DATA_DIR"
    log_info "Please export CSV files from SQL Server first"
    exit 1
fi
log_success "Data directory found"

# Function to load a table from CSV
load_table() {
    local table_name="$1"
    local csv_file="$DATA_DIR/${table_name}.csv"

    if [ ! -f "$csv_file" ]; then
        log_warning "CSV file not found: $csv_file (skipping)"
        return 1
    fi

    log_info "Loading: $table_name"

    # Load data using COPY command
    if docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" \
        -c "COPY perseus.${table_name} FROM STDIN WITH (FORMAT CSV, HEADER true, DELIMITER ',');" \
        < "$csv_file" >> "$LOG_FILE" 2>&1; then

        # Get row count
        local row_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c \
            "SELECT COUNT(*) FROM perseus.${table_name};" 2>/dev/null | tr -d ' ')

        log_success "  ✓ Loaded: $row_count rows"
        return 0
    else
        log_error "  ✗ Failed to load $table_name"
        return 1
    fi
}

# Function to load a tier of tables
load_tier() {
    local tier_number="$1"
    shift
    local tables=("$@")

    log_info "========================================";
    log_info "TIER $tier_number: Loading ${#tables[@]} tables"
    log_info "========================================";

    local loaded=0
    local failed=0

    for table in "${tables[@]}"; do
        if load_table "$table"; then
            ((loaded++))
        else
            ((failed++))
        fi
    done

    log_info "Tier $tier_number complete: $loaded loaded, $failed failed"
    echo ""
}

# Define tables by tier (based on dependency order)
TIER0_TABLES=(
    "Permissions"
    "PerseusTableAndRowCounts"
    "Scraper"
    "unit"
    "recipe_category"
    "recipe_type"
    "run_type"
    "transition_type"
    "workflow_type"
    "poll"
    "cm_unit_dimensions"
    "cm_user"
    "cm_user_group"
    "coa"
    "coa_spec"
    "color"
    "container"
    "container_type"
    "goo_type"
    "manufacturer"
    "display_layout"
    "display_type"
    "m_downstream"
    "external_goo_type"
    "m_upstream"
    "m_upstream_dirty_leaves"
    "goo_type_property_def"
    "field_map"
    "goo_qc"
    "smurf_robot"
    "smurf_robot_part"
    "property_type"
)

TIER1_TABLES=(
    "property"
    "robot_log_type"
    "container_type_position"
    "goo_type_combine_target"
    "container_history"
    "workflow"
    "perseus_user"
    "field_map_display_type"
    "field_map_display_type_user"
)

TIER2_TABLES=(
    "feed_type"
    "goo_type_combine_component"
    "material_inventory_threshold"
    "material_inventory_threshold_notify_user"
    "workflow_section"
    "workflow_attachment"
    "workflow_step"
    "recipe"
    "smurf_group"
    "smurf_goo_type"
    "property_option"
)

TIER3_TABLES=(
    "goo"
    "fatsmurf"
    "goo_attachment"
    "goo_comment"
    "goo_history"
    "fatsmurf_attachment"
    "fatsmurf_comment"
    "fatsmurf_history"
    "recipe_part"
    "smurf"
    "submission"
    "material_qc"
)

TIER4_TABLES=(
    "material_transition"
    "transition_material"
    "material_inventory"
    "fatsmurf_reading"
    "poll_history"
    "submission_entry"
    "robot_log"
    "robot_log_read"
    "robot_log_transfer"
    "robot_log_error"
    "robot_log_container_sequence"
)

# Main execution
if [ "$VALIDATE_ONLY" = true ]; then
    log_info "Validation mode: Checking data integrity only"
    docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" \
        < "${SCRIPT_DIR}/validate-referential-integrity.sql"
    exit 0
fi

# Load data tier by tier
if [ -z "$SPECIFIC_TIER" ]; then
    # Load all tiers
    load_tier 0 "${TIER0_TABLES[@]}"
    load_tier 1 "${TIER1_TABLES[@]}"
    load_tier 2 "${TIER2_TABLES[@]}"
    load_tier 3 "${TIER3_TABLES[@]}"
    load_tier 4 "${TIER4_TABLES[@]}"
else
    # Load specific tier
    case "$SPECIFIC_TIER" in
        0) load_tier 0 "${TIER0_TABLES[@]}" ;;
        1) load_tier 1 "${TIER1_TABLES[@]}" ;;
        2) load_tier 2 "${TIER2_TABLES[@]}" ;;
        3) load_tier 3 "${TIER3_TABLES[@]}" ;;
        4) load_tier 4 "${TIER4_TABLES[@]}" ;;
        *)
            log_error "Invalid tier: $SPECIFIC_TIER (must be 0-4)"
            exit 1
            ;;
    esac
fi

# Final validation
log_info "========================================";
log_info "DATA LOADING COMPLETE"
log_info "========================================";
log_info "Running final validation..."

docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" <<'EOF'
SELECT
    'Tables Loaded: ' || COUNT(DISTINCT table_name)::TEXT
FROM information_schema.tables
WHERE table_schema = 'perseus';

SELECT
    'Total Rows: ' || TO_CHAR(SUM(n_tup_ins), 'FM999,999,999')
FROM pg_stat_user_tables
WHERE schemaname = 'perseus';

SELECT
    'Foreign Keys: ' || COUNT(*)::TEXT
FROM information_schema.table_constraints
WHERE constraint_schema = 'perseus' AND constraint_type = 'FOREIGN KEY';
EOF

log_success "Data migration complete!"
log_info "Log file: $LOG_FILE"
log_info ""
log_info "Next steps:"
log_info "  1. Run validation: ./load-data.sh --validate-only"
log_info "  2. Check row counts: psql -c 'SELECT * FROM perseus.migration_stats;'"
log_info "  3. Run checksums: psql -f validate-checksums.sql"

exit 0
