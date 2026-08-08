#!/usr/bin/env bash
# Runs terraform validate on the dev environment (which includes all modules).
# Requires: terraform init to have been run first.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_DIR="$(dirname "$SCRIPT_DIR")/environments/dev"

echo "=== Validating Terraform configuration ==="
echo "Directory: $DEV_DIR"
echo ""

cd "$DEV_DIR"

# Initialize if needed (local backend)
if [ ! -d ".terraform" ]; then
  echo "Running terraform init..."
  terraform init -backend=false
  echo ""
fi

echo "Running terraform validate..."
if terraform validate; then
  echo ""
  echo "✓ Configuration is valid."
else
  echo ""
  echo "✗ Validation failed. Check errors above."
  exit 1
fi
