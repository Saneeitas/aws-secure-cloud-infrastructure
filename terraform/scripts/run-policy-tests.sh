#!/usr/bin/env bash
# Runs OPA/Conftest policy tests against a Terraform plan JSON output.
# Requires: conftest (https://www.conftest.dev/install/)
#
# Usage:
#   cd terraform/environments/dev
#   terraform plan -out=tfplan.binary
#   terraform show -json tfplan.binary > tfplan.json
#   ../../scripts/run-policy-tests.sh tfplan.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_DIR="$(dirname "$SCRIPT_DIR")/policies"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <plan-json-file>"
  echo ""
  echo "Generate the plan JSON with:"
  echo "  terraform plan -out=tfplan.binary"
  echo "  terraform show -json tfplan.binary > tfplan.json"
  exit 1
fi

PLAN_FILE="$1"

if [ ! -f "$PLAN_FILE" ]; then
  echo "Error: Plan file '$PLAN_FILE' not found."
  exit 1
fi

if ! command -v conftest &> /dev/null; then
  echo "Error: conftest is not installed."
  echo "Install it from: https://www.conftest.dev/install/"
  exit 1
fi

echo "=== Running Conftest policy checks ==="
echo "Plan file: $PLAN_FILE"
echo "Policy dir: $POLICY_DIR"
echo ""

conftest test "$PLAN_FILE" --policy "$POLICY_DIR" --all-namespaces

echo ""
echo "✓ All policy checks passed."
