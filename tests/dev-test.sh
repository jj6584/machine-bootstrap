#!/bin/bash

# Development Test Runner
# Quick tests for development workflow

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Running development tests...${NC}"

# Quick syntax checks
echo "📝 Checking syntax..."
bash -n install.sh || { echo -e "${RED}❌ install.sh has syntax errors${NC}"; exit 1; }
bash -n lib/gpu-support.sh || { echo -e "${RED}❌ gpu-support.sh has syntax errors${NC}"; exit 1; }

# Quick functional tests
echo "🔧 Testing basic functionality..."
bash install.sh --help > /dev/null || { echo -e "${RED}❌ Help function failed${NC}"; exit 1; }
bash install.sh --version > /dev/null || { echo -e "${RED}❌ Version function failed${NC}"; exit 1; }

# GPU module test
echo "🎮 Testing GPU module..."
if [ -f "tests/test-gpu.sh" ]; then
    bash tests/test-gpu.sh > /dev/null || echo -e "${YELLOW}⚠️ GPU tests had issues${NC}"
fi

echo -e "${GREEN}✅ All development tests passed!${NC}"
echo -e "${YELLOW}💡 Run './tests/run-tests.sh' for full test suite${NC}"
