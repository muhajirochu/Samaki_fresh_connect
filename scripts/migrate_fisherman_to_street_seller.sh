#!/usr/bin/env bash
# One-off data migration: rename `fishermanId` → `streetSellerId` across
# every Firestore document in the configured collections.
#
# Wave 3 of the cleanup removed the legacy role from the client code
# and the Firestore rules, but the production data still carries the
# old field name. Running this script against the live project
# completes the migration.
#
# Usage:
#   ./scripts/migrate_fisherman_to_street_seller.sh [--dry-run] [--project <id>] [--emulator]
#
# Flags:
#   --dry-run              Log every change without writing. Default: live.
#   --project <id>         Override the Firebase project id (default: from .firebaserc).
#   --emulator             Connect to the local Firestore emulator at 127.0.0.1:8080.
#
# Idempotence: a document is only mutated if `fishermanId` exists AND
# (`streetSellerId` is missing OR `streetSellerId` differs from
# `fishermanId`). `fishermanId` is deleted in the same write.
#
# Cross-platform note: this script is bash. On Windows, run it via
#   Git Bash (recommended), WSL, or use the PowerShell equivalent
#   scripts/migrate_fisherman_to_street_seller.ps1.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="${TMPDIR:-/tmp}/fb-migrate-$(date +%s)"
LOG_FILE="${PROJECT_ROOT}/firestore-migration.log"

# Defaults — overridden by flags below.
DRY_RUN=false
USE_EMULATOR=false
PROJECT_ID=""

# Parse argv.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --emulator) USE_EMULATOR=true; shift ;;
    --project) PROJECT_ID="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Resolve default project id from .firebaserc.
if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID=$(grep -o '"default": "[^"]*"' "${PROJECT_ROOT}/.firebaserc" | head -1 | cut -d'"' -f4)
  if [[ -z "$PROJECT_ID" ]]; then
    echo "No project id resolved; pass --project <id>." >&2
    exit 1
  fi
fi

# Ensure firebase-admin is installed in a temp dir.
if [ ! -d "$SCRIPT_DIR/node_modules/firebase-admin" ]; then
  echo "Installing firebase-admin in $SCRIPT_DIR..."
  mkdir -p "$SCRIPT_DIR"
  (cd "$SCRIPT_DIR" && npm init -y >/dev/null && npm install --no-fund --no-audit firebase-admin)
fi

# Export flags so the node script can read them.
export DRY_RUN USE_EMULATOR PROJECT_ID SCRIPT_DIR PROJECT_ROOT LOG_FILE

echo "Migration settings:"
echo "  Project:    $PROJECT_ID"
echo "  Emulator:   $USE_EMULATOR"
echo "  Dry-run:    $DRY_RUN"
echo "  Log file:   $LOG_FILE"
echo

node "${PROJECT_ROOT}/scripts/migrate_fisherman_to_street_seller.js"
