#!/bin/bash
set -e
cd /app
# Apply oracle patch
git apply /solution/solution.patch || git apply --reject /solution/solution.patch || patch -p1 < /solution/solution.patch
echo "Solution applied"
