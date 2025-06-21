#!/bin/bash

# Test GPU Support Module
# Simple test script to verify GPU support functionality

set -euo pipefail

echo "🧪 Testing GPU Support Module..."

# Source the GPU support module
if [ -f "lib/gpu-support.sh" ]; then
    source lib/gpu-support.sh
else
    echo "❌ GPU support module not found"
    exit 1
fi

echo "✅ GPU support module loaded successfully"

# Test GPU detection functions
echo "🔍 Testing GPU detection..."

if command -v lspci &> /dev/null; then
    echo "Testing lspci GPU detection:"
    lspci | grep -i vga || echo "No VGA devices found via lspci"
    lspci | grep -i 3d || echo "No 3D devices found via lspci"
else
    echo "⚠️ lspci not available, skipping hardware detection"
fi

# Test logging function
echo "📝 Testing logging functions..."
log_gpu "INFO" "This is a test info message"
log_gpu "WARN" "This is a test warning message"
log_gpu "SUCCESS" "This is a test success message"

# Test diagnostic function (non-destructive)
echo "🔍 Running GPU diagnostics..."
gpu_diagnostics

echo "✅ All GPU support tests completed successfully!"
