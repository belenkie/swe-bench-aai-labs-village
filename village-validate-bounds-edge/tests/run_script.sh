#!/bin/bash
set -e
# Village Node.js / tsx test runner — from village-clustering-antimeridian-fix template
# Supports MSL: run_script.sh receives selected_test_files_to_run as args, writes raw output for parser.py

run_all_tests() {
  echo "Running all Village tests..."
  cd /app
  env -u npm_config_registry npx tsx --test src/lib/geo.test.ts src/lib/clustering.test.ts src/lib/timezone.test.ts || true
  # fallback to all lib tests
  env -u npm_config_registry npx tsx --test 'src/lib/**/*.test.ts' || true
}

run_selected_tests() {
  local test_files=("$@")
  echo "Running selected tests: ${test_files[@]}"
  cd /app
  for test_file in "${test_files[@]}"; do
    test_path=$(echo "$test_file" | sed 's/::.*//' | cut -d',' -f1)
    echo "Running test: $test_path"
    if [ -f "$test_path" ]; then
      env -u npm_config_registry npx tsx --test "$test_path" || true
    else
      # try as pattern or with project root
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
