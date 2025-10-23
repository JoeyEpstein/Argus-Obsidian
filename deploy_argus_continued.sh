#!/bin/bash

# ============================================================================
# Argus-Obsidian Deployment Continuation
# Continues after Log Analytics Workspace is created
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if .env exists
if [ ! -f .env ]; then
    print_error ".env file not found. Please run fix_workspace.sh first"
    exit 1
fi

# Load environment variables
source .env

print_status "Continuing Argus-Obsidian deployment..."

# Create storage account for functions
print_status "Creating storage account..."
STORAGE_ACCOUNT_NAME="saargus$(openssl rand -hex 4)"
az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "rg-argus-obsidian" \
    --location "eastus" \
    --sku Standard_LRS \
    --kind StorageV2

# Deploy Azure Functions for B9-Phish connector
print_status "Deploying B9-Phish connector function..."
az functionapp create \
    --resource-group "rg-argus-obsidian" \
    --consumption-plan-location "eastus" \
    --runtime python \
    --runtime-version 3.9 \
    --functions-version 4 \
    --name "func-b9phish-connector" \
    --storage-account "$STORAGE_ACCOUNT_NAME" \
    --os-type Linux

# Set function app settings
print_status "Configuring function app settings..."
az functionapp config appsettings set \
    --name "func-b9phish-connector" \
    --resource-group "rg-argus-obsidian" \
    --settings "WORKSPACE_ID=$WORKSPACE_ID" "SHARED_KEY=$SHARED_KEY"

# Deploy RavenWatch connector
print_status "Deploying RavenWatch connector function..."
az functionapp create \
    --resource-group "rg-argus-obsidian" \
    --consumption-plan-location "eastus" \
    --runtime python \
    --runtime-version 3.9 \
    --functions-version 4 \
    --name "func-ravenwatch-connector" \
    --storage-account "$STORAGE_ACCOUNT_NAME" \
    --os-type Linux

az functionapp config appsettings set \
    --name "func-ravenwatch-connector" \
    --resource-group "rg-argus-obsidian" \
    --settings "WORKSPACE_ID=$WORKSPACE_ID" "SHARED_KEY=$SHARED_KEY"

# Deploy Arkkeeper connector
print_status "Deploying Arkkeeper connector function..."
az functionapp create \
    --resource-group "rg-argus-obsidian" \
    --consumption-plan-location "eastus" \
    --runtime python \
    --runtime-version 3.9 \
    --functions-version 4 \
    --name "func-arkkeeper-connector" \
    --storage-account "$STORAGE_ACCOUNT_NAME" \
    --os-type Linux

az functionapp config appsettings set \
    --name "func-arkkeeper-connector" \
    --resource-group "rg-argus-obsidian" \
    --settings "WORKSPACE_ID=$WORKSPACE_ID" "SHARED_KEY=$SHARED_KEY"

# Get function URLs
print_status "Retrieving function endpoints..."
B9PHISH_URL=$(az functionapp show \
    --name "func-b9phish-connector" \
    --resource-group "rg-argus-obsidian" \
    --query "defaultHostName" -o tsv)

RAVENWATCH_URL=$(az functionapp show \
    --name "func-ravenwatch-connector" \
    --resource-group "rg-argus-obsidian" \
    --query "defaultHostName" -o tsv)

ARKKEEPER_URL=$(az functionapp show \
    --name "func-arkkeeper-connector" \
    --resource-group "rg-argus-obsidian" \
    --query "defaultHostName" -o tsv)

# Update .env with endpoints
print_status "Updating .env with function endpoints..."
echo "" >> .env
echo "# Function Endpoints (auto-generated)" >> .env
echo "B9PHISH_ENDPOINT=https://$B9PHISH_URL" >> .env
echo "RAVENWATCH_ENDPOINT=https://$RAVENWATCH_URL" >> .env
echo "ARKKEEPER_ENDPOINT=https://$ARKKEEPER_URL" >> .env
echo "STORAGE_ACCOUNT=$STORAGE_ACCOUNT_NAME" >> .env

# Set up cost alerts
print_status "Setting up cost alerts..."
az consumption budget create \
    --budget-name "Argus-Monthly-Budget" \
    --resource-group "rg-argus-obsidian" \
    --amount 50 \
    --time-grain Monthly \
    --category Cost \
    --start-date $(date +%Y-%m-01) \
    --end-date $(date -v+1y +%Y-%m-%d) 2>/dev/null || {
    print_warning "Budget alerts may need to be configured through Azure Portal"
}

# Create Key Vault for secrets
print_status "Creating Key Vault for secure secret storage..."
KEYVAULT_NAME="kv-argus-$(openssl rand -hex 4)"
az keyvault create \
    --name "$KEYVAULT_NAME" \
    --resource-group "rg-argus-obsidian" \
    --location "eastus" \
    --sku standard

# Store secrets in Key Vault
print_status "Storing secrets in Key Vault..."
az keyvault secret set \
    --vault-name "$KEYVAULT_NAME" \
    --name "WorkspaceId" \
    --value "$WORKSPACE_ID"

az keyvault secret set \
    --vault-name "$KEYVAULT_NAME" \
    --name "WorkspaceKey" \
    --value "$SHARED_KEY"

# Generate deployment summary
print_status "Generating deployment summary..."
cat > deployment_summary.txt << EOF
========================================
Argus-Obsidian Deployment Summary
========================================
Date: $(date)

RESOURCE GROUP: rg-argus-obsidian
LOCATION: eastus

RESOURCES DEPLOYED:
✓ Log Analytics Workspace: law-argus-obsidian
✓ Microsoft Sentinel: Enabled
✓ Storage Account: $STORAGE_ACCOUNT_NAME
✓ Key Vault: $KEYVAULT_NAME

FUNCTION APPS:
✓ B9-Phish Connector: https://$B9PHISH_URL
✓ RavenWatch Connector: https://$RAVENWATCH_URL
✓ Arkkeeper Connector: https://$ARKKEEPER_URL

CREDENTIALS:
✓ Workspace ID: $WORKSPACE_ID
✓ Secrets stored in: $KEYVAULT_NAME

NEXT STEPS:
1. Deploy function code to each function app
2. Test data ingestion with sample data
3. Create detection rules in Sentinel
4. Build Logic App playbooks

USEFUL COMMANDS:
- View logs: az monitor log-analytics query -w $WORKSPACE_ID --analytics-query "union * | take 10"
- Check costs: az consumption usage list --query "[].{cost:pretaxCost}" --output table
- Function logs: az functionapp logs tail --name func-b9phish-connector --resource-group rg-argus-obsidian
EOF

cat deployment_summary.txt

# Final status
echo ""
echo "============================================================================"
echo -e "${GREEN}                 DEPLOYMENT COMPLETE! 🎉                                   ${NC}"
echo "============================================================================"
echo ""
echo "✅ All Azure resources have been deployed successfully!"
echo ""
echo "📋 Your function endpoints are:"
echo "   B9-Phish:    https://$B9PHISH_URL"
echo "   RavenWatch:  https://$RAVENWATCH_URL"
echo "   Arkkeeper:   https://$ARKKEEPER_URL"
echo ""
echo "🔐 Secrets stored in Key Vault: $KEYVAULT_NAME"
echo ""
echo "📁 Configuration saved to:"
echo "   - .env (local configuration)"
echo "   - deployment_summary.txt (full details)"
echo ""
echo "🎯 Next: Deploy your function code and start ingesting data!"
echo "============================================================================"

print_status "Ready to continue with Week 1 tasks!"
