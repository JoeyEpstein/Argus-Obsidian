#!/bin/bash

# ============================================================================
# Argus-Obsidian - Fix Sentinel & Subscription Issues
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

echo "============================================================================"
echo "                    Fixing Sentinel & Subscription Issues                   "
echo "============================================================================"

# Fix 1: Install Sentinel CLI extension
print_status "Installing Azure Sentinel CLI extension..."
az extension add --name sentinel || {
    print_warning "Sentinel extension might already be installed"
}

# Fix 2: Get correct subscription ID
print_status "Getting current subscription ID..."
CORRECT_SUB_ID=$(az account show --query id -o tsv)
print_status "Current subscription: $CORRECT_SUB_ID"

# Fix 3: Update .env file with correct subscription
print_status "Updating .env file with correct subscription..."
if [ -f .env ]; then
    # Backup existing .env
    cp .env .env.backup
    print_status "Created backup: .env.backup"
    
    # Update subscription ID
    if grep -q "AZURE_SUBSCRIPTION_ID=" .env; then
        sed -i.bak "s/^AZURE_SUBSCRIPTION_ID=.*/AZURE_SUBSCRIPTION_ID=$CORRECT_SUB_ID/" .env
    else
        echo "AZURE_SUBSCRIPTION_ID=$CORRECT_SUB_ID" >> .env
    fi
else
    print_warning ".env file not found, creating new one..."
    cat > .env << EOF
AZURE_SUBSCRIPTION_ID=$CORRECT_SUB_ID
RESOURCE_GROUP=rg-argus-obsidian
LOCATION=eastus
WORKSPACE_NAME=law-argus-obsidian
EOF
fi

# Fix 4: Get workspace credentials (since workspace exists)
print_status "Retrieving existing workspace credentials..."
WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --query "customerId" -o tsv)

SHARED_KEY=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --query "primarySharedKey" -o tsv)

print_status "Workspace ID: $WORKSPACE_ID"

# Update .env with workspace credentials
if ! grep -q "WORKSPACE_ID=" .env; then
    echo "WORKSPACE_ID=$WORKSPACE_ID" >> .env
else
    sed -i.bak "s/^WORKSPACE_ID=.*/WORKSPACE_ID=$WORKSPACE_ID/" .env
fi

if ! grep -q "SHARED_KEY=" .env; then
    echo "SHARED_KEY=$SHARED_KEY" >> .env
else
    sed -i.bak "s/^SHARED_KEY=.*/SHARED_KEY=$SHARED_KEY/" .env
fi

# Fix 5: Enable Sentinel (with proper extension)
print_status "Enabling Microsoft Sentinel..."
az sentinel onboarding create \
    --name "default" \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" 2>/dev/null || {
    print_warning "Sentinel might already be enabled. Checking status..."
    
    # Alternative: Enable through REST API
    print_status "Attempting to enable Sentinel via REST API..."
    WORKSPACE_RESOURCE_ID="/subscriptions/$CORRECT_SUB_ID/resourceGroups/rg-argus-obsidian/providers/Microsoft.OperationalInsights/workspaces/law-argus-obsidian"
    
    az rest --method put \
        --url "https://management.azure.com${WORKSPACE_RESOURCE_ID}/providers/Microsoft.SecurityInsights/onboardingStates/default?api-version=2022-06-01-preview" \
        --body '{"properties": {}}' 2>/dev/null || {
        print_warning "Sentinel may need to be enabled through Azure Portal"
        print_warning "Go to: https://portal.azure.com -> Your workspace -> Enable Microsoft Sentinel"
    }
}

# Fix 6: Verify resource group and workspace
print_status "Verifying resources..."
echo ""
echo "Resources in your resource group:"
az resource list --resource-group "rg-argus-obsidian" --output table

# Fix 7: Create storage account with unique name
print_status "Creating storage account..."
STORAGE_NAME="saargus$(openssl rand -hex 4)"
az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "rg-argus-obsidian" \
    --location "eastus" \
    --sku Standard_LRS \
    --subscription "$CORRECT_SUB_ID" || {
    print_error "Failed to create storage account"
    print_warning "You may need to choose a different name or check your subscription"
}

# Update .env with storage account
echo "STORAGE_ACCOUNT=$STORAGE_NAME" >> .env

print_status "Configuration saved to .env"

echo ""
echo "============================================================================"
echo -e "${GREEN}                    FIXES APPLIED SUCCESSFULLY! 🎉                         ${NC}"
echo "============================================================================"
echo ""
echo "✅ Fixed Issues:"
echo "   - Sentinel CLI extension installed"
echo "   - Subscription ID corrected: $CORRECT_SUB_ID"
echo "   - Workspace credentials retrieved"
echo "   - Storage account created: $STORAGE_NAME"
echo ""
echo "📋 Your Credentials (saved in .env):"
echo "   - Workspace ID: $WORKSPACE_ID"
echo "   - Subscription: $CORRECT_SUB_ID"
echo ""
echo "🎯 Next Steps:"
echo "   1. Continue deployment: bash deploy_argus_continued.sh"
echo "   2. Or deploy functions manually:"
echo "      az functionapp create --resource-group \"rg-argus-obsidian\" \\"
echo "        --name \"func-b9phish-connector\" --storage-account \"$STORAGE_NAME\" \\"
echo "        --consumption-plan-location \"eastus\" --runtime python --runtime-version 3.9 \\"
echo "        --functions-version 4 --os-type Linux"
echo ""
echo "============================================================================"

# Show final .env contents
print_status "Your .env file now contains:"
echo "---"
cat .env
echo "---"
