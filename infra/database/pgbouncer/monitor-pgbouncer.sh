#!/usr/bin/env bash
# PgBouncer Monitoring Script
# Displays real-time statistics and health metrics
#
# Usage: ./monitor-pgbouncer.sh [interval_seconds]
#
# Examples:
#   ./monitor-pgbouncer.sh        # Run once
#   ./monitor-pgbouncer.sh 5      # Refresh every 5 seconds
#   watch -n 10 ./monitor-pgbouncer.sh  # Alternative using watch

set -euo pipefail

# Future Enhancements Backlog Section
# 1. Create an env.conf file for setting up script for all initial variables
# 2. Password will be captured from userlist.txt
# 3. Review the entire scipt looking for bug or flaws in the execution logic, explore edge cases

# Configuration
PGHOST="localhost"
PGPORT="6432"
PGUSER="postgres"
PGDATABASE="pgbouncer"
INTERVAL="${1:-0}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Helper function to execute PgBouncer commands
pgb_query() {
    psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -tAc "$1" 2>/dev/null || echo "ERROR"
}

# Helper function to format numbers with thousand separators
format_number() {
    printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# Helper function to format bytes
format_bytes() {
    local bytes=$1
    if [ "${bytes}" -lt 1024 ]; then
        echo "${bytes} B"
    elif [ "${bytes}" -lt 1048576 ]; then
        echo "$(bc <<< "scale=2; ${bytes}/1024") KB"
    elif [ "${bytes}" -lt 1073741824 ]; then
        echo "$(bc <<< "scale=2; ${bytes}/1048576") MB"
    else
        echo "$(bc <<< "scale=2; ${bytes}/1073741824") GB"
    fi
}

# Display header
display_header() {
    clear
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║         PgBouncer Monitoring Dashboard - Perseus Project          ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}Host: ${PGHOST}:${PGPORT} | Database: ${PGDATABASE} | User: ${PGUSER}${NC}"
    echo -e "${BLUE}Timestamp: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# Display pool status
display_pools() {
    echo -e "${BOLD}${GREEN}Pool Status${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Get pool data
    local pool_data=$(psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" \
        -c "SHOW POOLS;" 2>/dev/null || echo "ERROR")

    if [ "${pool_data}" = "ERROR" ]; then
        echo -e "${RED}✗ Unable to connect to PgBouncer${NC}"
        return 1
    fi

    echo "${pool_data}" | grep -v "^$" | while IFS='|' read -r database user cl_active cl_waiting sv_active sv_idle sv_used sv_tested sv_login maxwait pool_mode; do
        # Skip header
        if [[ "${database}" == *"database"* ]]; then
            printf "%-15s %-15s %10s %10s %10s %10s %10s %10s\n" \
                "DATABASE" "USER" "CL_ACTIVE" "CL_WAIT" "SV_ACTIVE" "SV_IDLE" "SV_USED" "MAXWAIT"
            continue
        fi

        # Trim whitespace
        database=$(echo "${database}" | xargs)
        cl_waiting=$(echo "${cl_waiting}" | xargs)
        maxwait=$(echo "${maxwait}" | xargs)

        # Color code based on status
        local status_color="${GREEN}"
        if [ "${cl_waiting}" -gt 0 ]; then
            status_color="${YELLOW}"
        fi
        if [ "${cl_waiting}" -gt 10 ]; then
            status_color="${RED}"
        fi

        printf "${status_color}%-15s %-15s %10s %10s %10s %10s %10s %10s${NC}\n" \
            "${database}" "${user}" "${cl_active}" "${cl_waiting}" "${sv_active}" "${sv_idle}" "${sv_used}" "${maxwait}"
    done

    echo ""
}

# Display statistics
display_stats() {
    echo -e "${BOLD}${GREEN}Database Statistics${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local stats_data=$(psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" \
        -c "SHOW STATS;" 2>/dev/null || echo "ERROR")

    if [ "${stats_data}" = "ERROR" ]; then
        echo -e "${RED}✗ Unable to retrieve statistics${NC}"
        return 1
    fi

    echo "${stats_data}" | grep -v "^$" | while IFS='|' read -r database total_xact_count total_query_count total_received total_sent total_xact_time total_query_time total_wait_time avg_xact_count avg_query_count avg_recv avg_sent avg_xact_time avg_query_time avg_wait_time; do
        # Skip header
        if [[ "${database}" == *"database"* ]]; then
            printf "%-15s %12s %12s %15s %15s\n" \
                "DATABASE" "TRANSACTIONS" "QUERIES" "AVG_XACT_MS" "AVG_QUERY_MS"
            continue
        fi

        # Trim whitespace
        database=$(echo "${database}" | xargs)
        total_xact_count=$(echo "${total_xact_count}" | xargs)
        total_query_count=$(echo "${total_query_count}" | xargs)
        avg_xact_time=$(echo "${avg_xact_time}" | xargs)
        avg_query_time=$(echo "${avg_query_time}" | xargs)

        # Convert microseconds to milliseconds
        avg_xact_ms=$(bc <<< "scale=2; ${avg_xact_time}/1000" 2>/dev/null || echo "0")
        avg_query_ms=$(bc <<< "scale=2; ${avg_query_time}/1000" 2>/dev/null || echo "0")

        # Color code based on performance
        local perf_color="${GREEN}"
        if (( $(echo "${avg_xact_ms} > 1000" | bc -l) )); then
            perf_color="${YELLOW}"
        fi
        if (( $(echo "${avg_xact_ms} > 5000" | bc -l) )); then
            perf_color="${RED}"
        fi

        printf "${perf_color}%-15s %12s %12s %15s %15s${NC}\n" \
            "${database}" "${total_xact_count}" "${total_query_count}" "${avg_xact_ms}" "${avg_query_ms}"
    done

    echo ""
}

# Display active clients
display_clients() {
    echo -e "${BOLD}${GREEN}Active Client Connections${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local client_count=$(pgb_query "SELECT COUNT(*) FROM clients WHERE state != 'idle';")
    local total_clients=$(pgb_query "SELECT COUNT(*) FROM clients;")

    echo -e "Active: ${BOLD}${client_count}${NC} | Total: ${BOLD}${total_clients}${NC}"

    # Show top 5 clients by connection time
    psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" \
        -c "SHOW CLIENTS;" 2>/dev/null | head -10

    echo ""
}

# Display server connections
display_servers() {
    echo -e "${BOLD}${GREEN}PostgreSQL Server Connections${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local server_count=$(pgb_query "SELECT COUNT(*) FROM servers WHERE state = 'active';")
    local total_servers=$(pgb_query "SELECT COUNT(*) FROM servers;")

    echo -e "Active: ${BOLD}${server_count}${NC} | Total: ${BOLD}${total_servers}${NC}"

    # Show server distribution by state
    psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" \
        -c "SHOW SERVERS;" 2>/dev/null | head -10

    echo ""
}

# Display health summary
display_health() {
    echo -e "${BOLD}${GREEN}Health Summary${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check 1: PgBouncer responding
    local pgb_status=$(pgb_query "SELECT 1;" 2>/dev/null || echo "ERROR")
    if [ "${pgb_status}" = "1" ]; then
        echo -e "PgBouncer Status: ${GREEN}✓ Online${NC}"
    else
        echo -e "PgBouncer Status: ${RED}✗ Offline${NC}"
    fi

    # Check 2: Clients waiting
    local cl_waiting=$(pgb_query "SELECT SUM(cl_waiting) FROM pools;" || echo "0")
    if [ "${cl_waiting}" = "0" ] || [ -z "${cl_waiting}" ]; then
        echo -e "Waiting Clients: ${GREEN}✓ None${NC}"
    elif [ "${cl_waiting}" -lt 10 ]; then
        echo -e "Waiting Clients: ${YELLOW}⚠ ${cl_waiting} waiting${NC}"
    else
        echo -e "Waiting Clients: ${RED}✗ ${cl_waiting} waiting (CRITICAL)${NC}"
    fi

    # Check 3: Pool utilization
    local sv_active=$(pgb_query "SELECT SUM(sv_active) FROM pools WHERE database != 'pgbouncer';" || echo "0")
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local pgbouncer_ini="${script_dir}/pgbouncer.ini"

    local pool_size
    pool_size="$(grep -E '^[[:space:]]*default_pool_size' "${pgbouncer_ini}" 2>/dev/null | awk -F'=' '{gsub(/[[:space:]]/, "", $2); print $2}' || true)"
    pool_size="${pool_size:-25}"

    local utilization="0"
    if [ "${pool_size}" -gt 0 ] 2>/dev/null; then
        utilization=$(bc <<< "scale=2; (${sv_active}/${pool_size})*100" 2>/dev/null || echo "0")
    fi

    if (( $(echo "${utilization} < 50" | bc -l) )); then
        echo -e "Pool Utilization: ${GREEN}✓ ${utilization}% (${sv_active}/${pool_size})${NC}"
    elif (( $(echo "${utilization} < 80" | bc -l) )); then
        echo -e "Pool Utilization: ${YELLOW}⚠ ${utilization}% (${sv_active}/${pool_size})${NC}"
    else
        echo -e "Pool Utilization: ${RED}✗ ${utilization}% (${sv_active}/${pool_size}) - Consider increasing pool_size${NC}"
    fi

    # Check 4: PostgreSQL connectivity
    local pg_status=$(psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "perseus_dev" -tAc "SELECT 1;" 2>/dev/null || echo "ERROR")
    if [ "${pg_status}" = "1" ]; then
        echo -e "PostgreSQL: ${GREEN}✓ Accessible via PgBouncer${NC}"
    else
        echo -e "PostgreSQL: ${RED}✗ Cannot connect${NC}"
    fi

    echo ""
}

# Display configuration summary
display_config() {
    echo -e "${BOLD}${GREEN}Configuration Summary${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Read key configuration parameters
    psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" \
        -c "SHOW CONFIG;" 2>/dev/null | grep -E "pool_mode|default_pool_size|max_client_conn|server_lifetime|server_idle_timeout" || echo "Unable to retrieve config"

    echo ""
}

# Main monitoring loop
main() {
    while true; do
        display_header
        display_health
        display_pools
        display_stats
        # display_clients  # Uncomment for detailed client view
        # display_servers  # Uncomment for detailed server view
        # display_config   # Uncomment for config view

        # Exit if interval is 0 (single run)
        if [ "${INTERVAL}" -eq 0 ]; then
            break
        fi

        echo -e "${BLUE}Refreshing in ${INTERVAL} seconds... (Ctrl+C to exit)${NC}"
        sleep "${INTERVAL}"
    done
}

# Run main function
main
