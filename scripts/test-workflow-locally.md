# Testing Workflows Locally

## Option 1: YAML Validation (Quick Check)

```bash
# Validate YAML syntax
./scripts/validate-workflow.sh .github/workflows/approve-and-apply-service-infrastructure.yml

# Or validate all workflows
find .github/workflows -name "*.yml" -exec ./scripts/validate-workflow.sh {} \;
```

## Option 2: Test on a Branch First (Recommended)

1. **Create a test branch:**
   ```bash
   git checkout -b test/workflow-validation
   git push origin test/workflow-validation
   ```

2. **Test via GitHub UI:**
   - Go to Actions tab
   - Select the workflow
   - Click "Run workflow" on the test branch
   - Use test inputs

3. **If it works, merge to main:**
   ```bash
   git checkout main
   git merge test/workflow-validation
   git push origin main
   ```

## Option 3: Use `act` (Local GitHub Actions Runner)

**Install act:**
```bash
# macOS
brew install act

# Or download from: https://github.com/nektos/act
```

**Run workflow locally:**
```bash
# List workflows
act -l

# Run specific workflow (dry-run)
act workflow_dispatch -W .github/workflows/approve-and-apply-service-infrastructure.yml --dryrun

# Run with inputs (requires secrets)
act workflow_dispatch \
  -W .github/workflows/approve-and-apply-service-infrastructure.yml \
  --input application_name=test-service \
  --input stack_type="Containerized (GKE)" \
  --input port_context='{"runId":"test-run-id","approverEmail":"test@example.com"}' \
  --secret-file .secrets
```

**Create `.secrets` file:**
```bash
cat > .secrets <<EOF
PORT_CLIENT_ID=your_client_id
PORT_CLIENT_SECRET=your_client_secret
GH_PAT=your_github_token
EOF
```

**Note:** `act` has limitations:
- Some actions may not work perfectly
- Docker required
- May need to mock some actions

## Option 4: Manual Script Testing

Test individual steps:

```bash
# Test PR URL extraction
ENTITY_JSON='{"properties":{"pr_urls":["https://github.com/org/repo/pull/1","https://github.com/org/repo/pull/2"]}}'
echo "$ENTITY_JSON" | jq -r '.properties.pr_urls[0]'

# Test repository extraction
PR_URL="https://github.com/matar-Port-demo/test-repo/pull/123"
echo "$PR_URL" | sed -E 's|https://github.com/([^/]+/[^/]+)/pull/.*|\1|'
```

## Recommended Approach

1. ✅ **First:** Run YAML validation script
2. ✅ **Then:** Test on a branch via GitHub UI
3. ✅ **Finally:** Merge to main

This gives you confidence without risking main branch.

