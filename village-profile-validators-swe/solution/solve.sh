#!/bin/bash
set -e
cd /app
echo "Applying fix patch..."
git apply --whitespace=nowarn solution/solution.patch || git apply solution/solution.patch
echo "Patch applied"
