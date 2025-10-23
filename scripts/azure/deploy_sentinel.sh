#!/bin/bash

# Azure Sentinel Deployment Script
# Prerequisites: Azure CLI installed and authenticated

RESOURCE_GROUP="rg-argus-obsidian"
LOCATION="eastus"
WORKSPACE_NAME="law-argus-obsidian"
SENTINEL_NAME="argus-sentinel"

echo "🔧 Deploying Azure Resources..."

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --location $LOCATION \
  --retention-time 31

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --query id -o tsv)

# Enable Microsoft Sentinel
az sentinel onboarding create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --name "default"

echo "✅ Sentinel workspace deployed successfully!"
echo "Workspace ID: $WORKSPACE_ID"
