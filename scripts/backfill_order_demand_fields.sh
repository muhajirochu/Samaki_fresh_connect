#!/usr/bin/env bash
# One-off data migration: backfill `fishType` / `sellerLat` / `sellerLng`
# onto every existing `orders` document so the buyer dashboard's new
# "Popular Near You" demand aggregation can read completed-order
# volume without per-order join to the listings collection.
#
# New orders stamp the fields at create time (see
# `OrderService.createOrder` call sites). This script handles the
# historical orders that predate that change.
#
# Usage:
#   ./scripts/backfill_order_demand_fields.sh [--dry-run] [--project <id>] [--emulator]
#
# Flags:
#   --dry-run              Log every change without writing. Default: live.
#   --project <id>         Override the Firebase project id (default: from .firebaserc).
#   --emulator             Connect to the local Firestore emulator at 127.0.0.1:8080.
#
# Idempotence: a document is only mutated if at least one of the three
# target fields is missing. A re-run is a no-op.
#
# Cross-platform note: this script is bash. On Windows, run it via
#   Git Bash (recommended) or WSL.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="${TMPDIR:-/tmp}/fb-migrate-$(date +%s)"
LOG_FILE="${PROJECT_ROOT}/firestore-backfill-orders.log"

DRY_RUN=false
USE_EMULATOR=false
PROJECT_ID=""

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

if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID=$(grep -o '"default": "[^"]*"' "${PROJECT_ROOT}/.firebaserc" | head -1 | cut -d'"' -f4)
  if [[ -z "$PROJECT_ID" ]]; then
    echo "No project id resolved; pass --project <id>." >&2
    exit 1
  fi
fi

if [ ! -d "$SCRIPT_DIR/node_modules/firebase-admin" ]; then
  echo "Installing firebase-admin in $SCRIPT_DIR..."
  mkdir -p "$SCRIPT_DIR"
  (cd "$SCRIPT_DIR" && npm init -y >/dev/null && npm install --no-fund --no-audit firebase-admin)
fi

export DRY_RUN USE_EMULATOR PROJECT_ID SCRIPT_DIR PROJECT_ROOT LOG_FILE

echo "Backfill settings:"
echo "  Project:    $PROJECT_ID"
echo "  Emulator:   $USE_EMULATOR"
echo "  Dry-run:    $DRY_RUN"
echo "  Log file:   $LOG_FILE"
echo

node "${PROJECT_ROOT}/scripts/backfill_order_demand_fields.js"
