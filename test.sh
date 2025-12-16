#!/bin/bash

# Test script for llama-installer.sh
# Tests various installer options

set -e

echo "🧪 Testing llama-installer.sh"
echo "=============================="

# Test 1: Help
echo "Test 1: Help output"
./llama-installer.sh --help > /dev/null 2>&1
echo "✅ Help works"

# Test 2: Dry-run
echo -e "\nTest 2: Dry-run mode"
./llama-installer.sh -n
echo "✅ Dry-run works"

# Test 3: Custom directory
echo -e "\nTest 3: Custom directory (dry-run)"
./llama-installer.sh -n -d /tmp/test-custom-dir
echo "✅ Custom directory works"

# Test 4: Force flag
echo -e "\nTest 4: Force flag (dry-run)"
./llama-installer.sh -n -f
echo "✅ Force flag works"

# Test 5: Check only
echo -e "\nTest 5: Check only mode"
./llama-installer.sh --check-only
echo "✅ Check only works"

# Test 6: System detection
echo -e "\nTest 6: System detection"
./llama-installer.sh -n 2>&1 | grep -E "(Detected system|Detected GPU)"
echo "✅ System detection works"

echo -e "\n🎉 All tests passed!"
echo "Ready for real installation with: ./llama-installer.sh"