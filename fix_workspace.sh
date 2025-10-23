#!/bin/bash

# ============================================================================
# Argus-Obsidian Quick Fix - Log Analytics Workspace Deployment
# ============================================================================
# This fixes the ingestion-delay parameter error and continues deployment
# ============================================================================

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[✓]${NC} Running quick fix for Log Analytics Workspace deployment..."

# Deploy Log Analytics Workspace (without the problematic parameter)
echo -e "${GREEN}[✓]${NC} Creating Log Analytics Workspace..."
WORKSPACE_JSON=$(az monitor log-analytics workspace create \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --location "eastus" \
    --retention-time 31 \
    --query '{id:id, customerId:customerId}' \
    -o json)

# Extract workspace ID
WORKSPACE_ID=$(echo $WORKSPACE_JSON | python3 -c "import sys, json; print(json.load(sys.stdin)['customerId'])")
echo -e "${GREEN}[✓]${NC} Workspace ID: $WORKSPACE_ID"

# Get workspace shared key
echo -e "${GREEN}[✓]${NC} Retrieving workspace credentials..."
SHARED_KEY=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --query "primarySharedKey" -o tsv)

# Save credentials to .env file (append if exists, create if not)
if [ -f .env ]; then
    echo -e "${YELLOW}[!]${NC} Updating existing .env file..."
    # Update existing values
    sed -i.bak "s/^WORKSPACE_ID=.*/WORKSPACE_ID=$WORKSPACE_ID/" .env
    sed -i.bak "s/^SHARED_KEY=.*/SHARED_KEY=$SHARED_KEY/" .env
else
    echo -e "${GREEN}[✓]${NC} Creating new .env file..."
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    cat > .env << EOF
# Azure Configuration
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
WORKSPACE_ID=$WORKSPACE_ID
SHARED_KEY=$SHARED_KEY
RESOURCE_GROUP=rg-argus-obsidian
LOCATION=eastus
WORKSPACE_NAME=law-argus-obsidian

# Integration Endpoints (to be filled)
B9PHISH_ENDPOINT=
RAVENWATCH_ENDPOINT=
ARKKEEPER_ENDPOINT=
EOF
fi

# Enable Microsoft Sentinel
echo -e "${GREEN}[✓]${NC} Enabling Microsoft Sentinel..."
az sentinel onboarding create \
    --name "default" \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" 2>/dev/null || {
    echo -e "${YELLOW}[!]${NC} Sentinel might already be enabled or needs to be enabled through Azure Portal"
}

# Check if workspace was created successfully
echo -e "${GREEN}[✓]${NC} Verifying workspace creation..."
WORKSPACE_STATE=$(az monitor log-analytics workspace show \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --query "provisioningState" -o tsv)

if [ "$WORKSPACE_STATE" == "Succeeded" ]; then
    echo -e "${GREEN}[✓]${NC} Log Analytics Workspace successfully created!"
    echo ""
    echo "============================================================================"
    echo -e "${GREEN}SUCCESS!${NC} Workspace is ready"
    echo "============================================================================"
    echo "Workspace ID: $WORKSPACE_ID"
    echo "Credentials saved to: .env"
    echo ""
    echo "Next steps:"
    echo "1. Continue with storage account creation:"
    echo "   az storage account create --name \"saargus\$(openssl rand -hex 4)\" --resource-group \"rg-argus-obsidian\" --location \"eastus\" --sku Standard_LRS"
    echo ""
    echo "2. Or run the complete deployment (skip workspace creation):"
    echo "   bash deploy_argus_continued.sh"
else
    echo -e "${YELLOW}[!]${NC} Workspace state: $WORKSPACE_STATE"
    echo "Please check Azure Portal for any issues"
fi
