#!/bin/bash

# Cleanup script to delete GitHub repositories created in the last hour
# Usage: ./cleanup-test-repos.sh [org-name]

set -e

ORG_NAME="${1:-matar-Port-demo}"
GITHUB_TOKEN="${GH_PAT:-$GITHUB_TOKEN}"

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ Error: GH_PAT or GITHUB_TOKEN environment variable must be set"
  exit 1
fi

echo "🔍 Searching for repositories in organization: $ORG_NAME"
echo "⏰ Created in the last hour..."

# Calculate timestamp for 1 hour ago
ONE_HOUR_AGO=$(date -u -v-1H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "-1 hour" +"%Y-%m-%dT%H:%M:%SZ")

echo "📅 Looking for repos created after: $ONE_HOUR_AGO"
echo ""

# Get all repositories from the organization
REPOS=$(curl -s -X GET \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/$ORG_NAME/repos?per_page=100&sort=created&direction=desc")

# Filter repositories created in the last hour
REPOS_TO_DELETE=$(echo "$REPOS" | jq -r --arg cutoff "$ONE_HOUR_AGO" '
  .[] | 
  select(.created_at >= $cutoff) | 
  "\(.name)|\(.created_at)|\(.html_url)"
')

if [ -z "$REPOS_TO_DELETE" ]; then
  echo "✅ No repositories found created in the last hour"
  exit 0
fi

echo "📋 Found repositories to delete:"
echo "$REPOS_TO_DELETE" | while IFS='|' read -r name created_at url; do
  echo "  - $name (created: $created_at)"
done

echo ""
read -p "⚠️  Are you sure you want to delete these repositories? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Cancelled"
  exit 0
fi

echo ""
echo "🗑️  Deleting repositories..."

DELETED_COUNT=0
FAILED_COUNT=0

echo "$REPOS_TO_DELETE" | while IFS='|' read -r name created_at url; do
  echo -n "Deleting $name... "
  
  RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$ORG_NAME/$name")
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" = "204" ]; then
    echo "✅ Deleted"
    DELETED_COUNT=$((DELETED_COUNT + 1))
  else
    echo "❌ Failed (HTTP $HTTP_CODE)"
    echo "$BODY" | jq -r '.message // .' 2>/dev/null || echo "$BODY"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
done

echo ""
echo "✨ Cleanup complete!"
echo "   Deleted: $DELETED_COUNT"
echo "   Failed: $FAILED_COUNT"

