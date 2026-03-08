#!/bin/bash

# Integration Test Runner Script
# Runs all integration tests by priority

set -e

echo "=========================================="
echo "Running Integration Tests"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL=0
PASSED=0
FAILED=0

run_test_suite() {
  local priority=$1
  local path=$2
  local description=$3
  
  echo ""
  echo "=========================================="
  echo "Priority: $priority - $description"
  echo "=========================================="
  
  if [ ! -d "$path" ]; then
    echo "${YELLOW}⚠ Directory not found: $path${NC}"
    return
  fi
  
  local test_files=$(find "$path" -name "*_test.dart")
  local count=$(echo "$test_files" | wc -l)
  
  echo "Found $count test files"
  echo ""
  
  for test_file in $test_files; do
    TOTAL=$((TOTAL + 1))
    echo "Running: $(basename $test_file)"
    
    if flutter test "$test_file" --reporter compact; then
      PASSED=$((PASSED + 1))
      echo "${GREEN}✅ PASSED${NC}"
    else
      FAILED=$((FAILED + 1))
      echo "${RED}❌ FAILED${NC}"
    fi
    echo ""
  done
}

# Run tests by priority
run_test_suite "P0" "integration_test/tests/p0" "Critical"
run_test_suite "P1" "integration_test/tests/p1" "High Priority"
run_test_suite "P2" "integration_test/tests/p2" "Medium Priority"
run_test_suite "P3" "integration_test/tests/p3" "Low Priority"

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total:  $TOTAL"
echo "${GREEN}Passed: $PASSED${NC}"
echo "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "${GREEN}🎉 All tests passed!${NC}"
  exit 0
else
  echo "${RED}⚠ Some tests failed${NC}"
  exit 1
fi
