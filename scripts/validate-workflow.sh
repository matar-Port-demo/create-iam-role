#!/bin/bash

# Script to validate GitHub Actions workflow YAML syntax
# Usage: ./scripts/validate-workflow.sh [workflow-file]

set -e

WORKFLOW_FILE="${1:-.github/workflows/approve-and-apply-service-infrastructure.yml}"

echo "🔍 Validating workflow: $WORKFLOW_FILE"

# Check if yamllint is available
if ! command -v yamllint &> /dev/null; then
  echo "⚠️  yamllint not found. Installing..."
  pip3 install yamllint --quiet || {
    echo "❌ Failed to install yamllint. Please install manually: pip3 install yamllint"
    exit 1
  }
fi

# Check if actionlint is available (better GitHub Actions validation)
if ! command -v actionlint &> /dev/null; then
  echo "⚠️  actionlint not found. Installing..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install actionlint || {
      echo "⚠️  Could not install actionlint via brew. Skipping advanced validation."
    }
  else
    echo "⚠️  actionlint not available. Install from: https://github.com/rhymond/actionlint"
  fi
fi

echo ""
echo "1️⃣  Running yamllint..."
yamllint "$WORKFLOW_FILE" && echo "✅ YAML syntax is valid" || {
  echo "❌ YAML syntax errors found"
  exit 1
}

if command -v actionlint &> /dev/null; then
  echo ""
  echo "2️⃣  Running actionlint (GitHub Actions validation)..."
  actionlint "$WORKFLOW_FILE" && echo "✅ GitHub Actions syntax is valid" || {
    echo "⚠️  Some warnings found (may not be critical)"
  }
else
  echo ""
  echo "2️⃣  Skipping actionlint (not installed)"
fi

echo ""
echo "3️⃣  Checking for common issues..."

# Check if Port action version is correct
if grep -q "port-labs/port-github-action@v[^1]" "$WORKFLOW_FILE"; then
  echo "⚠️  Warning: Found Port action version other than v1"
else
  echo "✅ Port action version is v1"
fi

# Check for required secrets
REQUIRED_SECRETS=("PORT_CLIENT_ID" "PORT_CLIENT_SECRET" "GH_PAT")
for secret in "${REQUIRED_SECRETS[@]}"; do
  if grep -q "\${{ secrets.$secret }}" "$WORKFLOW_FILE"; then
    echo "✅ Found reference to secret: $secret"
  else
    echo "⚠️  Warning: No reference to secret: $secret"
  fi
done

# Check for common syntax issues
if grep -q "::set-output" "$WORKFLOW_FILE"; then
  echo "⚠️  Warning: Found deprecated ::set-output syntax (should use GITHUB_OUTPUT)"
fi

echo ""
echo "✅ Basic validation complete!"
echo ""
echo "💡 To test the workflow fully, use 'act' or test on a branch first."

