#!/bin/bash
set -e

# Village AAI Labs - Node.js / tsx test runner
# Supports both frontend (src/lib) and backend (server) tests via tsx --test

run_all_tests() {
  echo "Running all Village tests..."
  cd /app
  # Default to clustering tests + all lib tests for this task family
  # Use env -u to bypass any bad npm_config_registry if set
  env -u npm_config_registry npx tsx --test src/lib/clustering.test.ts || true
}

run_selected_tests() {
  local test_files=("$@")
  echo "Running selected tests: ${test_files[@]}"
  cd /app

  for test_file in "${test_files[@]}"; do
    # Strip ::test_name suffix if present (pytest style)
    test_path=$(echo "$test_file" | sed 's/::.*//')
    echo "Running test: $test_path"
    # Support both comma-separated and space-separated
    if [ -f "$test_path" ]; then
      env -u npm_config_registry npx tsx --test "$test_path" || true
    else
      echo "Test file not found: $test_path, trying as-is"
      env -u npm_config_registry npx tsx --test "$test_file" || true
    fi
  done
}

if [ $# -eq 0 ]; then
  run_all_tests
  exit $?
fi

if [[ "$1" == *","* ]]; then
  IFS=',' read -r -a TEST_FILES <<< "$1"
else
  TEST_FILES=("$@")
fi

run_selected_tests "${TEST_FILES[@]}"
