#!/bin/bash
set -e
# Harbor/Msl compatible test.sh — writes reward.txt 1/0

cd /app

# Run selected tests if provided via env or args — we rely on run_script.sh + parser.py for MSL
# For local harbor oracle check: run tests then write reward
mkdir -p /logs/verifier

# If FAIL_TO_PASS env available, check manually? Simplified: if npm test exits 0 we consider pass for oracle.
# Actual grading uses parser.py + config.json FAIL_TO_PASS/PASS_TO_PASS via MSL.

# For local quick check:
if [ -f "tests/run_script.sh" ]; then
  bash tests/run_script.sh 2>&1 | tee /tmp/test_out.txt
else
  npx tsx --test src/lib/geo.test.ts 2>&1 | tee /tmp/test_out.txt || true
fi

# Simple heuristic: if no FAIL in output, reward 1 else 0 (real grading via parser.py in MSL)
if grep -q "✖\|FAIL\|not ok\|FAILED" /tmp/test_out.txt; then
  echo "0" > /logs/verifier/reward.txt
else
  echo "1" > /logs/verifier/reward.txt
fi
cat /logs/verifier/reward.txt
