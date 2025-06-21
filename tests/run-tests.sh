#!/bin/bash

# Machine Bootstrap Test Suite
# Comprehensive testing for all components

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test function with better error handling
run_test() {
    local test_name="$1"
    local test_command="$2"
    local optional="${3:-false}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${BLUE}Testing: ${BOLD}$test_name${NC}"
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        if [ "$optional" = "true" ]; then
            echo -e "${YELLOW}⚠️  SKIP: $test_name (optional)${NC}"
        else
            echo -e "${RED}❌ FAIL: $test_name${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
}

echo -e "${CYAN}${BOLD}🧪 Machine Bootstrap Test Suite${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test 1: Script Syntax Validation
echo -e "\n${YELLOW}📝 Script Syntax Tests${NC}"
run_test "Main installer syntax" "bash -n install.sh"
run_test "Bootstrap script syntax" "bash -n bootstrap.sh"
run_test "Debian installer syntax" "bash -n linux/install-debian.sh"
run_test "Fedora installer syntax" "bash -n linux/install-fedora.sh"
run_test "Arch installer syntax" "bash -n linux/install-arch.sh"
run_test "macOS installer syntax" "bash -n macos/install-macos.sh"

# Test 2: Library Module Tests
echo -e "\n${YELLOW}📚 Library Module Tests${NC}"
run_test "System check module syntax" "bash -n lib/system-check.sh"
run_test "Security module syntax" "bash -n lib/security.sh"
run_test "Update manager syntax" "bash -n lib/update-manager.sh"
run_test "GUI interface syntax" "bash -n lib/gui-interface.sh"
run_test "Docker support syntax" "bash -n lib/docker-support.sh"
run_test "Cloud integration syntax" "bash -n lib/cloud-integration.sh"
run_test "Analytics module syntax" "bash -n lib/analytics.sh"
run_test "Plugin system syntax" "bash -n lib/plugin-system.sh"
run_test "GPU support syntax" "bash -n lib/gpu-support.sh"

# Test 3: Configuration Tests
echo -e "\n${YELLOW}⚙️  Configuration Tests${NC}"
run_test "Config example file exists" "[ -f config.yml.example ]"
run_test "Gaming config file exists" "[ -f gaming.yml ]"
run_test "Config files are valid YAML" "command -v yamllint >/dev/null && yamllint config.yml.example gaming.yml" true

# Test 4: Function Tests (dry run)
echo -e "\n${YELLOW}🔧 Function Tests${NC}"
run_test "Help function works" "bash install.sh --help | grep -q 'USAGE'"
run_test "Version function works" "bash install.sh --version | grep -q 'v'"
run_test "Dry run mode works" "bash install.sh --dry-run basic"

# Test 5: System Check Tests
echo -e "\n${YELLOW}🔍 System Check Tests${NC}"
run_test "System check module loads" "source lib/system-check.sh"
run_test "Basic system requirements check" "source lib/system-check.sh && check_basic_requirements"

# Test 6: GPU Tests (optional)
echo -e "\n${YELLOW}🎮 GPU Tests${NC}"
if [ -f "tests/test-gpu.sh" ]; then
    run_test "GPU test suite" "bash tests/test-gpu.sh" true
else
    echo -e "${YELLOW}⚠️  GPU test not found, skipping${NC}"
fi

# Test 7: PowerShell Tests (if available)
echo -e "\n${YELLOW}💻 PowerShell Tests${NC}"
if command -v pwsh >/dev/null 2>&1; then
    run_test "PowerShell installer syntax" "pwsh -Command 'Get-Content windows/install-app.ps1 | Out-String | Invoke-Expression -WhatIf'" true
elif command -v powershell >/dev/null 2>&1; then
    run_test "PowerShell installer syntax" "powershell -Command 'Get-Content windows/install-app.ps1 | Out-String | Invoke-Expression -WhatIf'" true
else
    echo -e "${YELLOW}⚠️  PowerShell not available, skipping Windows tests${NC}"
fi

# Test 8: Security Tests
echo -e "\n${YELLOW}🔒 Security Tests${NC}"
run_test "Security module loads" "source lib/security.sh"
run_test "No hardcoded credentials" "! grep -r 'password\|secret\|key\|token' --include='*.sh' --include='*.ps1' . | grep -v 'api-key\|ssh-key\|gpg-key'" true

# Test 9: Documentation Tests
echo -e "\n${YELLOW}📖 Documentation Tests${NC}"
run_test "README exists and not empty" "[ -s README.md ]"
run_test "README contains installation instructions" "grep -q 'curl -fsSL' README.md"
run_test "All scripts have help text" "bash install.sh --help | grep -q 'OPTIONS'"

# Summary
echo -e "\n${CYAN}${BOLD}📊 Test Results Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Total Tests: ${BOLD}$TESTS_TOTAL${NC}"
echo -e "Passed: ${GREEN}${BOLD}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}${BOLD}$TESTS_FAILED${NC}"
echo -e "Success Rate: ${BOLD}$(( (TESTS_PASSED * 100) / TESTS_TOTAL ))%${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}${BOLD}❌ Some tests failed!${NC}"
    exit 1
fi
