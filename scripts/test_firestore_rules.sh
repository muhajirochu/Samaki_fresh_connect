#!/usr/bin/env bash
# Run Firestore rules unit tests against the local emulator.
# Usage: ./scripts/test_firestore_rules.sh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="/tmp/fb-rules-test"

# 1. Ensure test deps are installed (one-time)
if [ ! -d "$TEST_DIR/node_modules/@firebase/rules-unit-testing" ]; then
  echo "Installing @firebase/rules-unit-testing in $TEST_DIR..."
  mkdir -p "$TEST_DIR"
  (cd "$TEST_DIR" && npm init -y >/dev/null && npm install --no-fund --no-audit @firebase/rules-unit-testing firebase)
fi

# 2. Copy the latest rules + test script
cp "$PROJECT_ROOT/firestore.rules.test.js" "$TEST_DIR/test.js"

# 3. Start emulator, run tests, kill emulator
echo "Starting Firestore emulator..."
firebase emulators:exec --only firestore --project samaki-fresh \
  "cd $TEST_DIR && node test.js"