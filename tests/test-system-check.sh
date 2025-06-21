#!/bin/bash

# Unit Tests for System Check Module
# Tests individual functions in isolation

set -euo pipefail

# Source the module
source "$(dirname "$0")/../lib/system-check.sh"

# Test counter
TESTS=0
PASSED=0

test_function() {
    local test_name="$1"
    local expected="$2"
    shift 2
    local result
    
    TESTS=$((TESTS + 1))
    
    if result=$("$@" 2>/dev/null); then
        if [ "$result" = "$expected" ] || [ "$expected" = "any" ]; then
            echo "✅ $test_name"
            PASSED=$((PASSED + 1))
        else
            echo "❌ $test_name (expected: $expected, got: $result)"
        fi
    else
        if [ "$expected" = "fail" ]; then
            echo "✅ $test_name (correctly failed)"
            PASSED=$((PASSED + 1))
        else
            echo "❌ $test_name (function failed)"
        fi
    fi
}

echo "🔍 Testing System Check Module Functions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test basic requirements check
test_function "Basic requirements check" "any" check_basic_requirements

# Test disk space check (assuming some free space exists)
test_function "Disk space check" "any" check_disk_space

# Test RAM check
test_function "RAM check" "any" check_ram

# Test internet connectivity
test_function "Internet connectivity" "any" check_internet_connectivity

echo ""
echo "Results: $PASSED/$TESTS tests passed"

if [ $PASSED -eq $TESTS ]; then
    exit 0
else
    exit 1
fi
