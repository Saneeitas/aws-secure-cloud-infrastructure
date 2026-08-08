#!/usr/bin/env bash
# Validates Terraform formatting across all modules and environments.
# Exit code 0 = all files formatted correctly.
# Exit code non-zero = files need formatting (run: terraform fmt -recursive)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Checking Terraform formatting ==="
echo "Directory: $TERRAFORM_DIR"
echo ""

if terraform fmt -check -recursive "$TERRAFORM_DIR"; then
  echo ""
  echo "✓ All Terraform files are properly formatted."
else
  echo ""
  echo "✗ Some files need formatting. Run: terraform fmt -recursive $TERRAFORM_DIR"
  exit 1
fi
