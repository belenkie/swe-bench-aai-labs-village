#!/bin/bash
set -e
mkdir -p /logs/verifier
echo "Running verifier via run_script.sh..."
bash tests/run_script.sh "$@" 2>&1 | tee /logs/verifier/run.log || true

echo "Parsing results..."
python3 tests/parser.py /logs/verifier/run.log /logs/verifier/run.log /tmp/results.json || true
cat /tmp/results.json || echo '{ "tests": [] }'

if grep -q "FAIL" /logs/verifier/run.log; then
  echo "0" > /tmp/reward.txt 2>/dev/null || echo "0" > reward.txt
  echo "Some tests FAILED"
else
  echo "1" > /tmp/reward.txt 2>/dev/null || echo "1" > reward.txt
  echo "All tests PASSED"
fi
cat /tmp/reward.txt 2>/dev/null || echo "0" > /app/reward.txt
mkdir -p /logs && cp /tmp/reward.txt /logs/reward.txt 2>/dev/null || cp /tmp/reward.txt /app/reward.txt 2>/dev/null || true
echo "Reward written"
