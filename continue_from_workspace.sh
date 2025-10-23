#!/bin/bash

# ============================================================================
# Argus-Obsidian - Simple Continuation from Current State
# ============================================================================
# Your workspace exists, let's continue from there
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[✓]${NC} Starting fresh from your current state..."

# 1. Source the fixed .env file
if [ -f .env ]; then
    source .env
    echo -e "${GREEN}[✓]${NC} Loaded configuration from .env"
else
    echo "Please run fix_sentinel_subscription.sh first!"
    exit 1
fi

# 2. Create Function Apps
echo -e "${GREEN}[✓]${NC} Creating B9-Phish connector function..."
az functionapp create \
    --resource-group "rg-argus-obsidian" \
    --consumption-plan-location "eastus" \
    --runtime python \
    --runtime-version 3.9 \
    --functions-version 4 \
    --name "func-b9phish-connector" \
    --storage-account "$STORAGE_ACCOUNT" \
    --os-type Linux

echo -e "${GREEN}[✓]${NC} Configuring B9-Phish function..."
az functionapp config appsettings set \
    --name "func-b9phish-connector" \
    --resource-group "rg-argus-obsidian" \
    --settings "WORKSPACE_ID=$WORKSPACE_ID" "SHARED_KEY=$SHARED_KEY"

echo -e "${GREEN}[✓]${NC} Creating RavenWatch connector function..."
az functionapp create \
    --resource-group "rg-argus-obsidian" \
    --consumption-plan-location "eastus" \
    --runtime python \
    --runtime-version 3.9 \
    --functions-version 4 \
    --name "func-ravenwatch-connector" \
    --storage-account "$STORAGE_ACCOUNT" \
    --os-type Linux

echo -e "${GREEN}[✓]${NC} Configuring RavenWatch function..."
az functionapp config appsettings set \
    --name "func-ravenwatch-connector" \
    --resource-group "rg-argus-obsidian" \
    --settings "WORKSPACE_ID=$WORKSPACE_ID" "SHARED_KEY=$SHARED_KEY"

echo -e "${GREEN}[✓]${NC} Creating Arkkeeper connector function..."
az functionapp create \
    --resource-group "rg-argus-obsidian" \
    --consumption-plan-location "eastus" \
    --runtime python \
    --runtime-version 3.9 \
    --functions-version 4 \
    --name "func-arkkeeper-connector" \
    --storage-account "$STORAGE_ACCOUNT" \
    --os-type Linux

echo -e "${GREEN}[✓]${NC} Configuring Arkkeeper function..."
az functionapp config appsettings set \
    --name "func-arkkeeper-connector" \
    --resource-group "rg-argus-obsidian" \
    --settings "WORKSPACE_ID=$WORKSPACE_ID" "SHARED_KEY=$SHARED_KEY"

# 3. Get Function URLs
echo -e "${GREEN}[✓]${NC} Retrieving function URLs..."
B9PHISH_URL=$(az functionapp show --name "func-b9phish-connector" --resource-group "rg-argus-obsidian" --query "defaultHostName" -o tsv)
RAVENWATCH_URL=$(az functionapp show --name "func-ravenwatch-connector" --resource-group "rg-argus-obsidian" --query "defaultHostName" -o tsv)
ARKKEEPER_URL=$(az functionapp show --name "func-arkkeeper-connector" --resource-group "rg-argus-obsidian" --query "defaultHostName" -o tsv)

# 4. Update .env with URLs
echo "" >> .env
echo "# Function URLs" >> .env
echo "B9PHISH_URL=https://$B9PHISH_URL" >> .env
echo "RAVENWATCH_URL=https://$RAVENWATCH_URL" >> .env
echo "ARKKEEPER_URL=https://$ARKKEEPER_URL" >> .env

# 5. Show summary
echo ""
echo "============================================================================"
echo -e "${GREEN}                    DEPLOYMENT COMPLETE! 🎉                               ${NC}"
echo "============================================================================"
echo ""
echo "✅ Resources Created:"
echo "   - Log Analytics Workspace: law-argus-obsidian ✓"
echo "   - B9-Phish Function: https://$B9PHISH_URL"
echo "   - RavenWatch Function: https://$RAVENWATCH_URL"
echo "   - Arkkeeper Function: https://$ARKKEEPER_URL"
echo ""
echo "🔑 Your Workspace Credentials:"
echo "   - Workspace ID: $WORKSPACE_ID"
echo ""
echo "📋 All Resources:"
az resource list --resource-group "rg-argus-obsidian" --query "[].{Name:name, Type:type}" --output table
echo ""
echo "💰 Check your costs:"
echo "   az consumption usage list --query \"[].{cost:pretaxCost}\" --output table"
echo ""
echo "🎯 Next: Deploy function code to start ingesting data!"
echo "============================================================================"
