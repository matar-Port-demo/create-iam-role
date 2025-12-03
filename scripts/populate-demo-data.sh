#!/bin/bash

# Script to populate missing properties in provisioningRequest entities for demo

set -e

BLUEPRINT_ID="provisioningRequest"
PORT_API_URL="https://api.getport.io"

# Get access token
echo "🔐 Getting Port access token..."
ACCESS_TOKEN=$(curl -s -X POST "${PORT_API_URL}/v1/auth/access_token" \
  -H "Content-Type: application/json" \
  -d "{\"clientId\": \"${PORT_CLIENT_ID}\", \"clientSecret\": \"${PORT_CLIENT_SECRET}\"}" | jq -r '.accessToken')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
  echo "❌ Failed to get access token"
  exit 1
fi

echo "✅ Got access token"

# List all entities
echo "📋 Fetching all entities in ${BLUEPRINT_ID} blueprint..."
ENTITIES=$(curl -s -X POST "${PORT_API_URL}/v1/entities/search" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"rules\": [
      {\"property\": \"\$blueprint\", \"operator\": \"=\", \"value\": \"${BLUEPRINT_ID}\"}
    ],
    \"combinator\": \"and\"
  }")

ENTITY_COUNT=$(echo "$ENTITIES" | jq '.entities | length')
echo "Found ${ENTITY_COUNT} entities"

# Process each entity
echo "$ENTITIES" | jq -c '.entities[]' | while read -r entity; do
  ENTITY_ID=$(echo "$entity" | jq -r '.identifier')
  ENTITY_TITLE=$(echo "$entity" | jq -r '.title')
  
  echo ""
  echo "📦 Processing: ${ENTITY_ID} - ${ENTITY_TITLE}"
  
  # Check current properties
  CURRENT_PROPS=$(echo "$entity" | jq '.properties // {}')
  
  # Build update payload with demo data for missing properties
  UPDATE_PROPS=$(echo "$CURRENT_PROPS" | jq '
    . +
    (if .terraform_plan == null or .terraform_plan == "" then {
      "terraform_plan": "```\nTerraform will perform the following actions:\n\n  # google_container_cluster.cluster will be created\n  + resource \"google_container_cluster\" \"cluster\" {\n      + name     = \"demo-cluster\"\n      + location = \"us-central1\"\n      + initial_node_count = 3\n      + node_config {\n          + machine_type = \"e2-medium\"\n          + disk_size_gb = 100\n        }\n    }\n\nPlan: 1 to add, 0 to change, 0 to destroy.\n```"
    } else {} end) +
    (if .terraform_resource == null or .terraform_resource == "" then {
      "terraform_resource": {
        "resource_type": "google_container_cluster",
        "resource_name": (.resource_name // "demo-cluster"),
        "project_id": "demo-project-123",
        "region": "us-central1",
        "cluster_endpoint": "https://" + (.resource_name // "demo-cluster") + ".us-central1.gke.cloud.google.com",
        "resource_id": "projects/demo-project-123/locations/us-central1/clusters/" + (.resource_name // "demo-cluster")
      }
    } else {} end) +
    (if .pr_url == null or .pr_url == "" then {
      "pr_url": "https://github.com/matar-Port-demo/create-iam-role/pull/123"
    } else {} end) +
    (if .port_run_link == null or .port_run_link == "" then {
      "port_run_link": "https://app.getport.io/organization/run?runId=" + .identifier
    } else {} end)
  ')
  
  # Check if there are any updates needed
  if [ "$(echo "$CURRENT_PROPS" | jq 'to_entries | length')" -lt "$(echo "$UPDATE_PROPS" | jq 'to_entries | length')" ]; then
    echo "  ✏️  Updating missing properties..."
    
    RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X PATCH "${PORT_API_URL}/v1/entities/${BLUEPRINT_ID}/${ENTITY_ID}" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"properties\": ${UPDATE_PROPS}}")
    
    HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')
    
    if [ "$HTTP_STATUS" == "200" ]; then
      echo "  ✅ Updated successfully"
    else
      echo "  ❌ Failed to update. HTTP Status: ${HTTP_STATUS}"
      echo "  Response: ${BODY}"
    fi
  else
    echo "  ✓ All properties already set"
  fi
done

echo ""
echo "✨ Done!"



