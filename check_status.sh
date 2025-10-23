#!/bin/bash

# Argus-Obsidian Deployment Status Check
echo "============================================"
echo "     Argus-Obsidian Deployment Status      "
echo "============================================"
echo ""

# Check subscription
echo "📋 Current Azure Subscription:"
az account show --query "{Name:name, ID:id, State:state}" --output table
echo ""

# Check resource group
echo "📁 Resource Group Status:"
az group show --name "rg-argus-obsidian" --query "{Name:name, Location:location, State:properties.provisioningState}" --output table 2>/dev/null || echo "❌ Resource group not found"
echo ""

# Check workspace
echo "📊 Log Analytics Workspace:"
az monitor log-analytics workspace show --resource-group "rg-argus-obsidian" --workspace-name "law-argus-obsidian" --query "{Name:name, Location:location, RetentionDays:retentionInDays, State:provisioningState}" --output table 2>/dev/null || echo "❌ Workspace not found"
echo ""

# Check if Sentinel extension is installed
echo "🔧 Azure CLI Extensions:"
if az extension list | grep -q sentinel; then
    echo "✅ Sentinel extension is installed"
else
    echo "❌ Sentinel extension NOT installed - Run: az extension add --name sentinel"
fi
echo ""

# List all resources
echo "📦 All Resources in Resource Group:"
az resource list --resource-group "rg-argus-obsidian" --query "[].{Name:name, Type:type}" --output table 2>/dev/null || echo "No resources found"
echo ""

# Check for storage accounts
echo "💾 Storage Accounts:"
az storage account list --resource-group "rg-argus-obsidian" --query "[].{Name:name, Status:statusOfPrimary}" --output table 2>/dev/null || echo "No storage accounts found"
echo ""

# Check for function apps
echo "⚡ Function Apps:"
az functionapp list --resource-group "rg-argus-obsidian" --query "[].{Name:name, State:state, Runtime:runtimeVersion}" --output table 2>/dev/null || echo "No function apps found"
echo ""

# Check costs
echo "💰 Cost Summary (Last 7 Days):"
START_DATE=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)
az consumption usage list --start-date $START_DATE --end-date $END_DATE --query "[?contains(instanceId, 'rg-argus-obsidian')].{Service:meterDetails.meterCategory, Cost:pretaxCost, Unit:unit}" --output table 2>/dev/null || echo "Unable to retrieve cost data"
echo ""

echo "============================================"
echo "           What's Next?                    "
echo "============================================"
echo ""

# Check what needs to be done
if ! az monitor log-analytics workspace show --resource-group "rg-argus-obsidian" --workspace-name "law-argus-obsidian" &>/dev/null; then
    echo "❌ Need to create Log Analytics Workspace"
elif ! az extension list | grep -q sentinel; then
    echo "⚠️  Need to install Sentinel extension: az extension add --name sentinel"
elif ! az storage account list --resource-group "rg-argus-obsidian" --query "[0]" &>/dev/null; then
    echo "⚠️  Need to create storage account"
elif ! az functionapp list --resource-group "rg-argus-obsidian" --query "[0]" &>/dev/null; then
    echo "⚠️  Need to create function apps"
else
    echo "✅ Basic infrastructure appears to be in place!"
    echo "Next: Deploy function code and test data ingestion"
fi
echo ""
