#!/bin/bash

# ShellCheck wrapper for CI
# This script runs shellcheck with appropriate exclusions for our project

set -euo pipefail

echo "🔍 Running ShellCheck on all shell scripts..."

# Find all shell scripts except .git directory
scripts=$(find . -name "*.sh" -not -path "./.git/*")

if [ -z "$scripts" ]; then
    echo "No shell scripts found"
    exit 1
fi

# Run shellcheck with appropriate exclusions
# SC2016: Expressions don't expand in single quotes (we intentionally use single quotes for literal strings)
# SC2034: Variable appears unused (some variables are used in sourced scripts)
shellcheck_exit_code=0

for script in $scripts; do
    echo "Checking: $script"
    if ! shellcheck -e SC2034,SC2016 "$script"; then
        shellcheck_exit_code=1
    fi
done

if [ $shellcheck_exit_code -eq 0 ]; then
    echo "✅ All shell scripts passed ShellCheck"
else
    echo "❌ Some shell scripts failed ShellCheck"
fi

exit $shellcheck_exit_code
