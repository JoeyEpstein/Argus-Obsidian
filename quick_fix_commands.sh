# Quick Fix Commands for Argus-Obsidian
# Run these commands one by one in your terminal

# 1. First, make sure you're in your project directory
cd ~/Desktop/Argus-Obsidian  # or wherever your repo is

# 2. Create the Log Analytics Workspace (WITHOUT the problematic parameter)
az monitor log-analytics workspace create \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --location "eastus" \
    --retention-time 31

# 3. Get the Workspace ID (you'll need this)
WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --query "customerId" -o tsv)
echo "Workspace ID: $WORKSPACE_ID"

# 4. Get the Shared Key (save this!)
SHARED_KEY=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --query "primarySharedKey" -o tsv)
echo "Shared Key: $SHARED_KEY"

# 5. Enable Sentinel
az sentinel onboarding create \
    --name "default" \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian"

# 6. Create storage account
STORAGE_NAME="saargus$(openssl rand -hex 4)"
az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "rg-argus-obsidian" \
    --location "eastus" \
    --sku Standard_LRS

# 7. Create your first Function App
az functionapp create \
    --resource-group "rg-argus-obsidian" \
    --consumption-plan-location "eastus" \
    --runtime python \
    --runtime-version 3.9 \
    --functions-version 4 \
    --name "func-b9phish-connector" \
    --storage-account "$STORAGE_NAME" \
    --os-type Linux

# 8. Configure the function with your workspace credentials
az functionapp config appsettings set \
    --name "func-b9phish-connector" \
    --resource-group "rg-argus-obsidian" \
    --settings "WORKSPACE_ID=$WORKSPACE_ID" "SHARED_KEY=$SHARED_KEY"

# 9. Save your credentials to .env file
cat > .env << EOF
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
WORKSPACE_ID=$WORKSPACE_ID
SHARED_KEY=$SHARED_KEY
RESOURCE_GROUP=rg-argus-obsidian
LOCATION=eastus
WORKSPACE_NAME=law-argus-obsidian
STORAGE_ACCOUNT=$STORAGE_NAME
EOF

echo "✅ Basic setup complete! Check your .env file for credentials."
