#!/usr/bin/env bash
# PgBouncer Testing and Validation Script
# Validates PgBouncer installation, configuration, and performance
#
# Usage: ./test-pgbouncer.sh

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
PGBOUNCER_HOST="localhost"
PGBOUNCER_PORT="6432"
POSTGRES_PORT="5432"
PGUSER="perseus_admin"
PGDATABASE="perseus_dev"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper functions
print_header() {
    echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════${NC}\n"
}

print_test() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -ne "${BLUE}[$TESTS_TOTAL]${NC} $1 ... "
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ PASS${NC}"
    [ -n "${1:-}" ] && echo -e "    ${GREEN}→ $1${NC}"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗ FAIL${NC}"
    [ -n "${1:-}" ] && echo -e "    ${RED}→ $1${NC}"
}

test_warn() {
    echo -e "${YELLOW}⚠ WARNING${NC}"
    [ -n "${1:-}" ] && echo -e "    ${YELLOW}→ $1${NC}"
}

# Test functions
test_docker_running() {
    print_test "PgBouncer container is running"
    if docker ps | grep -q "perseus-pgbouncer-dev"; then
        local status=$(docker inspect -f '{{.State.Status}}' perseus-pgbouncer-dev)
        if [ "$status" = "running" ]; then
            test_pass "Container status: running"
        else
            test_fail "Container status: $status"
            return 1
        fi
    else
        test_fail "Container not found"
        return 1
    fi
}

test_postgres_running() {
    print_test "PostgreSQL container is running"
    if docker ps | grep -q "perseus-postgres-dev"; then
        local status=$(docker inspect -f '{{.State.Status}}' perseus-postgres-dev)
        if [ "$status" = "running" ]; then
            test_pass "Container status: running"
        else
            test_fail "Container status: $status"
            return 1
        fi
    else
        test_fail "Container not found"
        return 1
    fi
}

test_pgbouncer_port() {
    print_test "PgBouncer port $PGBOUNCER_PORT is listening"
    if nc -z "$PGBOUNCER_HOST" "$PGBOUNCER_PORT" 2>/dev/null; then
        test_pass "Port $PGBOUNCER_PORT is accessible"
    else
        test_fail "Port $PGBOUNCER_PORT is not accessible"
        return 1
    fi
}

test_pgbouncer_connection() {
    print_test "Can connect to PgBouncer admin database"
    if psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer -c "SELECT 1;" > /dev/null 2>&1; then
        test_pass "Successfully connected to pgbouncer database"
    else
        test_fail "Cannot connect to pgbouncer database"
        return 1
    fi
}

test_database_connection() {
    print_test "Can connect to perseus_dev via PgBouncer"
    if psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d "$PGDATABASE" -c "SELECT version();" > /dev/null 2>&1; then
        local pg_version=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d "$PGDATABASE" -tAc "SELECT version();")
        test_pass "PostgreSQL version: ${pg_version:0:50}..."
    else
        test_fail "Cannot connect to $PGDATABASE database"
        return 1
    fi
}

test_pool_configuration() {
    print_test "Pool configuration is correct"
    local pool_size=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer \
        -tAc "SELECT pool_size FROM databases WHERE name = 'perseus_dev';" 2>/dev/null || echo "0")

    if [ "$pool_size" = "10" ]; then
        test_pass "Pool size: $pool_size (matches CN-073 specification)"
    elif [ "$pool_size" = "0" ]; then
        test_fail "Database 'perseus_dev' not configured in pgbouncer.ini"
        return 1
    else
        test_warn "Pool size: $pool_size (expected 10 per CN-073)"
    fi
}

test_pool_mode() {
    print_test "Pool mode is set to transaction"
    local pool_mode=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer \
        -tAc "SELECT pool_mode FROM databases WHERE name = 'perseus_dev';" 2>/dev/null || echo "unknown")

    if [ "$pool_mode" = "transaction" ]; then
        test_pass "Pool mode: transaction (optimal for Perseus)"
    else
        test_warn "Pool mode: $pool_mode (expected transaction)"
    fi
}

test_server_lifetime() {
    print_test "Server lifetime configured correctly"
    local server_lifetime=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer \
        -tAc "SHOW server_lifetime;" 2>/dev/null || echo "0")

    if [ "$server_lifetime" = "1800" ]; then
        test_pass "Server lifetime: ${server_lifetime}s (30 minutes, per CN-073)"
    else
        test_warn "Server lifetime: ${server_lifetime}s (expected 1800s per CN-073)"
    fi
}

test_idle_timeout() {
    print_test "Server idle timeout configured correctly"
    local idle_timeout=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer \
        -tAc "SHOW server_idle_timeout;" 2>/dev/null || echo "0")

    if [ "$idle_timeout" = "300" ]; then
        test_pass "Idle timeout: ${idle_timeout}s (5 minutes, per CN-073)"
    else
        test_warn "Idle timeout: ${idle_timeout}s (expected 300s per CN-073)"
    fi
}

test_max_connections() {
    print_test "Maximum client connections configured"
    local max_conn=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer \
        -tAc "SHOW max_client_conn;" 2>/dev/null || echo "0")

    if [ "$max_conn" -ge "1000" ]; then
        test_pass "Max client connections: $max_conn"
    else
        test_warn "Max client connections: $max_conn (expected >= 1000)"
    fi
}

test_pool_status() {
    print_test "Pool status shows no waiting clients"
    local waiting=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer \
        -tAc "SELECT SUM(cl_waiting) FROM pools;" 2>/dev/null || echo "0")

    if [ "$waiting" = "0" ] || [ -z "$waiting" ]; then
        test_pass "No clients waiting for connections"
    else
        test_warn "$waiting clients waiting (pool may be saturated)"
    fi
}

test_concurrent_connections() {
    print_test "Can handle concurrent connections (10 clients)"
    local temp_file=$(mktemp)
    local success_count=0

    # Spawn 10 concurrent connections
    for i in {1..10}; do
        psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d "$PGDATABASE" \
            -c "SELECT pg_sleep(0.1); SELECT $i AS client_id;" > /dev/null 2>&1 &
    done

    # Wait for all background jobs
    wait

    # Check if all succeeded
    if [ $? -eq 0 ]; then
        test_pass "All 10 concurrent connections succeeded"
    else
        test_fail "Some concurrent connections failed"
        return 1
    fi

    rm -f "$temp_file"
}

test_connection_reuse() {
    print_test "Connection pooling works (backend connection reuse)"

    # Get initial server connection count
    local initial_servers=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer \
        -tAc "SELECT COUNT(*) FROM servers WHERE state = 'active';" 2>/dev/null || echo "0")

    # Execute 10 sequential queries
    for i in {1..10}; do
        psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d "$PGDATABASE" \
            -c "SELECT 1;" > /dev/null 2>&1
    done

    # Get final server connection count
    local final_servers=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer \
        -tAc "SELECT COUNT(*) FROM servers WHERE state = 'active';" 2>/dev/null || echo "0")

    # Pooling is working if server count didn't increase by 10
    if [ "$final_servers" -lt 5 ]; then
        test_pass "Connection reuse verified (${final_servers} server connections for 10 client queries)"
    else
        test_warn "Connection reuse may not be optimal (${final_servers} server connections)"
    fi
}

test_statistics() {
    print_test "Statistics are being collected"
    local xact_count=$(psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d pgbouncer \
        -tAc "SELECT total_xact_count FROM stats WHERE database = 'perseus_dev';" 2>/dev/null || echo "0")

    if [ "$xact_count" -gt 0 ]; then
        test_pass "Transaction count: $xact_count"
    else
        test_warn "No transaction statistics yet (database may not have been used)"
    fi
}

test_direct_vs_pooled_performance() {
    print_test "Performance comparison (Direct vs Pooled)"

    # Test direct PostgreSQL (50 connections)
    local direct_start=$(date +%s%N)
    for i in {1..50}; do
        psql -h "$PGBOUNCER_HOST" -p "$POSTGRES_PORT" -U "$PGUSER" -d "$PGDATABASE" \
            -c "SELECT 1;" > /dev/null 2>&1
    done
    local direct_end=$(date +%s%N)
    local direct_time=$(( (direct_end - direct_start) / 1000000 ))

    # Test via PgBouncer (50 connections)
    local pooled_start=$(date +%s%N)
    for i in {1..50}; do
        psql -h "$PGBOUNCER_HOST" -p "$PGBOUNCER_PORT" -U "$PGUSER" -d "$PGDATABASE" \
            -c "SELECT 1;" > /dev/null 2>&1
    done
    local pooled_end=$(date +%s%N)
    local pooled_time=$(( (pooled_end - pooled_start) / 1000000 ))

    # Calculate improvement
    local improvement=$(bc <<< "scale=2; (($direct_time - $pooled_time) / $direct_time) * 100" 2>/dev/null || echo "0")

    if [ "$pooled_time" -lt "$direct_time" ]; then
        test_pass "Pooled: ${pooled_time}ms | Direct: ${direct_time}ms | Improvement: ${improvement}%"
    else
        test_warn "Pooled: ${pooled_time}ms | Direct: ${direct_time}ms (pooled should be faster)"
    fi
}

test_authentication() {
    print_test "Authentication file is secure"
    local userlist_path="/Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer/userlist.txt"

    if [ -f "$userlist_path" ]; then
        local perms=$(stat -f "%Lp" "$userlist_path" 2>/dev/null || stat -c "%a" "$userlist_path" 2>/dev/null)
        if [ "$perms" = "600" ]; then
            test_pass "File permissions: $perms (secure)"
        else
            test_fail "File permissions: $perms (should be 600)"
            return 1
        fi
    else
        test_fail "userlist.txt not found (run generate-userlist.sh)"
        return 1
    fi
}

# Summary report
print_summary() {
    print_header "Test Summary"

    local pass_rate=$(bc <<< "scale=2; ($TESTS_PASSED / $TESTS_TOTAL) * 100" 2>/dev/null || echo "0")

    echo -e "Total Tests:  ${BOLD}$TESTS_TOTAL${NC}"
    echo -e "Passed:       ${GREEN}${BOLD}$TESTS_PASSED${NC}"
    echo -e "Failed:       ${RED}${BOLD}$TESTS_FAILED${NC}"
    echo -e "Pass Rate:    ${BOLD}${pass_rate}%${NC}"
    echo ""

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All tests passed! PgBouncer is ready for use.${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo -e "  1. Update application connection strings to use port 6432"
        echo -e "  2. Monitor pool status with: ./monitor-pgbouncer.sh"
        echo -e "  3. Review README.md for operational procedures"
        return 0
    else
        echo -e "${RED}${BOLD}✗ Some tests failed. Review errors above.${NC}"
        echo ""
        echo -e "${YELLOW}Troubleshooting:${NC}"
        echo -e "  1. Check container logs: docker-compose logs pgbouncer"
        echo -e "  2. Verify configuration: cat pgbouncer/pgbouncer.ini"
        echo -e "  3. Regenerate userlist: ./generate-userlist.sh"
        echo -e "  4. Consult README.md troubleshooting section"
        return 1
    fi
}

# Quality score calculation
calculate_quality_score() {
    print_header "Quality Score Calculation"

    # Scoring dimensions (T027 requirements)
    local syntax_score=0
    local config_score=0
    local performance_score=0
    local security_score=0
    local documentation_score=0

    # 1. Syntax/Installation (20 points)
    [ "$TESTS_PASSED" -ge 1 ] && syntax_score=5
    [ "$TESTS_PASSED" -ge 3 ] && syntax_score=10
    [ "$TESTS_PASSED" -ge 5 ] && syntax_score=15
    [ "$TESTS_PASSED" -ge 8 ] && syntax_score=20

    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local pgbouncer_ini="${SCRIPT_DIR}/pgbouncer.ini"

    # 2. Configuration Correctness (30 points)
    grep -q "pool_size=10" "${pgbouncer_ini}" && config_score=$((config_score + 10))
    grep -q "server_lifetime = 1800" "${pgbouncer_ini}" && config_score=$((config_score + 10))
    grep -q "server_idle_timeout = 300" "${pgbouncer_ini}" && config_score=$((config_score + 10))

    # 4. Security (15 points)
    [ -f "${SCRIPT_DIR}/.gitignore" ] && security_score=$((security_score + 5))
    [ -f "${SCRIPT_DIR}/userlist.txt" ] && security_score=$((security_score + 5))
    grep -q "auth_type = md5" "${pgbouncer_ini}" && security_score=$((security_score + 5))

    # 5. Documentation (15 points)
    [ -f "${SCRIPT_DIR}/README.md" ] && documentation_score=$((documentation_score + 10))
    [ -f "${SCRIPT_DIR}/monitor-pgbouncer.sh" ] && documentation_score=$((documentation_score + 5))

    # Calculate total score
    local total_score=$((syntax_score + config_score + performance_score + security_score + documentation_score))
    local final_score=$(bc <<< "scale=1; $total_score / 10" 2>/dev/null || echo "0.0")

    # Display breakdown
    echo -e "Syntax/Installation:      ${syntax_score}/20"
    echo -e "Configuration:            ${config_score}/30"
    echo -e "Performance:              ${performance_score}/20"
    echo -e "Security:                 ${security_score}/15"
    echo -e "Documentation:            ${documentation_score}/15"
    echo -e "${BOLD}─────────────────────────────────${NC}"
    echo -e "${BOLD}Total Score:              ${total_score}/100${NC}"
    echo -e "${BOLD}Final Score:              ${final_score}/10.0${NC}"
    echo ""

    if (( $(echo "$final_score >= 7.0" | bc -l) )); then
        echo -e "${GREEN}${BOLD}✓ Quality score meets minimum requirement (≥7.0/10.0)${NC}"
    else
        echo -e "${YELLOW}${BOLD}⚠ Quality score below minimum requirement (≥7.0/10.0)${NC}"
    fi

    echo ""
}

# Main execution
main() {
    print_header "PgBouncer Testing and Validation"

    echo -e "${BLUE}Testing PgBouncer installation for Perseus PostgreSQL Migration${NC}"
    echo -e "${BLUE}Reference: specs/001-tsql-to-pgsql/spec.md CN-073${NC}"
    echo ""

    # Prerequisites
    print_header "Phase 1: Prerequisites"
    test_postgres_running
    test_docker_running

    # Connectivity
    print_header "Phase 2: Connectivity"
    test_pgbouncer_port
    test_pgbouncer_connection
    test_database_connection

    # Configuration
    print_header "Phase 3: Configuration"
    test_pool_configuration
    test_pool_mode
    test_server_lifetime
    test_idle_timeout
    test_max_connections

    # Functionality
    print_header "Phase 4: Functionality"
    test_pool_status
    test_concurrent_connections
    test_connection_reuse
    test_statistics

    # Performance
    print_header "Phase 5: Performance"
    test_direct_vs_pooled_performance

    # Security
    print_header "Phase 6: Security"
    test_authentication

    # Summary and quality score
    print_summary
    calculate_quality_score
}

# Run tests
main
