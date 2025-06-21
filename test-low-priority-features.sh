#!/bin/bash

# Test script for all low-priority features
# Validates that all new modules work correctly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo -e "${CYAN}🧪 Testing Machine Bootstrap Low-Priority Features${NC}"
echo ""

# Test 1: Plugin System
echo -e "${YELLOW}1. Plugin System Tests${NC}"
run_test "Plugin system initialization" "bash lib/plugin-system.sh init"
run_test "Plugin creation" "bash lib/plugin-system.sh create test-plugin"
run_test "Plugin listing" "bash lib/plugin-system.sh list"

# Test 2: Analytics System
echo -e "${YELLOW}2. Analytics System Tests${NC}"
run_test "Analytics status check" "bash lib/analytics.sh status"
run_test "Analytics stats display" "bash lib/analytics.sh stats"

# Test 3: Cloud Integration
echo -e "${YELLOW}3. Cloud Integration Tests${NC}"
run_test "Cloud tools listing" "bash lib/cloud-integration.sh list"

# Test 4: Docker Support
echo -e "${YELLOW}4. Docker Support Tests${NC}"
run_test "Docker support module syntax" "bash -n lib/docker-support.sh"

# Test 5: GUI Interface
echo -e "${YELLOW}5. GUI Interface Tests${NC}"
run_test "GUI interface module syntax" "bash -n lib/gui-interface.sh"

# Test 6: Main Installer Integration
echo -e "${YELLOW}6. Main Installer Integration Tests${NC}"
run_test "Help with new options" "bash install.sh --help | grep -q '\\-\\-gui'"
run_test "Help with Docker option" "bash install.sh --help | grep -q '\\-\\-docker'"
run_test "Help with plugins option" "bash install.sh --help | grep -q '\\-\\-plugins'"
run_test "Help with analytics option" "bash install.sh --help | grep -q '\\-\\-analytics'"
run_test "Help with cloud option" "bash install.sh --help | grep -q '\\-\\-cloud'"

# Test 7: Example Scripts
echo -e "${YELLOW}7. Example Scripts Tests${NC}"
run_test "Complete features example" "bash -n examples/complete-features.sh"

# Test 8: Module Dependencies
echo -e "${YELLOW}8. Module Dependencies Tests${NC}"
run_test "All modules have execute permissions" "[ -x lib/plugin-system.sh ] && [ -x lib/analytics.sh ] && [ -x lib/docker-support.sh ] && [ -x lib/cloud-integration.sh ]"

# Test 9: Configuration
echo -e "${YELLOW}9. Configuration Tests${NC}"
run_test "Plugin config directory created" "[ -d ~/.config/machine-bootstrap/plugins ]"

# Test 10: Documentation
echo -e "${YELLOW}10. Documentation Tests${NC}"
run_test "README mentions GUI" "grep -q 'GUI interface' README.md"
run_test "README mentions Docker" "grep -q 'Docker support' README.md"
run_test "README mentions plugins" "grep -q 'Plugin system' README.md"
run_test "README mentions analytics" "grep -q 'analytics' README.md"
run_test "README mentions cloud" "grep -q 'Cloud integration' README.md"

echo ""
echo -e "${CYAN}📊 Test Results${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All tests passed! Low-priority features are working correctly.${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please check the implementation.${NC}"
    exit 1
fi
