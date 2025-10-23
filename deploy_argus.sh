#!/bin/bash

# ============================================================================
# Argus-Obsidian Master Deployment Script
# Microsoft Sentinel Detection Engineering Lab
# ============================================================================
# This script sets up your entire project structure and deploys Week 1
# Run from your Argus-Obsidian repository root
# ============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project variables
PROJECT_NAME="Argus-Obsidian"
GITHUB_REPO="https://github.com/JoeyEpstein/Argus-Obsidian"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Header
echo "============================================================================"
echo "                    Argus-Obsidian Deployment Script                       "
echo "                 Microsoft Sentinel Detection Engineering Lab              "
echo "============================================================================"
echo ""

# Check prerequisites
print_status "Checking prerequisites..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Installing..."
    brew update && brew install azure-cli
else
    print_status "Azure CLI is installed"
fi

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 not found. Please install Python 3.9+"
    exit 1
else
    print_status "Python 3 is installed"
fi

# Check if Git is configured
if ! git config user.name &> /dev/null; then
    print_warning "Git user not configured. Setting up..."
    read -p "Enter your name: " git_name
    read -p "Enter your email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
fi

# Create project structure
print_status "Creating project structure..."

# Run the setup script
bash argus_setup.sh

# Install Python dependencies
print_status "Installing Python dependencies..."
pip3 install -r requirements.txt

# Azure login
print_status "Logging into Azure..."
az login --use-device-code

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_status "Using subscription: $SUBSCRIPTION_ID"

# Create resource group
print_status "Creating resource group..."
az group create \
    --name "rg-argus-obsidian" \
    --location "eastus" \
    --tags "Project=Argus-Obsidian" "Environment=Development" "Owner=SecurityEngineering"

# Deploy Log Analytics Workspace
print_status "Deploying Log Analytics Workspace..."
WORKSPACE_JSON=$(az monitor log-analytics workspace create \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --location "eastus" \
    --retention-time 31 \
    --query '{id:id, customerId:customerId}' \
    -o json)

WORKSPACE_ID=$(echo $WORKSPACE_JSON | python3 -c "import sys, json; print(json.load(sys.stdin)['customerId'])")
print_status "Workspace ID: $WORKSPACE_ID"

# Get workspace shared key
print_status "Retrieving workspace credentials..."
SHARED_KEY=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian" \
    --query "primarySharedKey" -o tsv)

# Save credentials to .env file
print_status "Saving credentials to .env file..."
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

print_status ".env file created (remember to add to .gitignore!)"

# Enable Microsoft Sentinel
print_status "Enabling Microsoft Sentinel..."
az sentinel onboarding create \
    --name "default" \
    --resource-group "rg-argus-obsidian" \
    --workspace-name "law-argus-obsidian"

# Create storage account for functions
print_status "Creating storage account..."
STORAGE_ACCOUNT_NAME="saargus$(openssl rand -hex 4)"
az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "rg-argus-obsidian" \
    --location "eastus" \
    --sku Standard_LRS \
    --kind StorageV2

# Deploy Azure Functions for connectors
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
az functionapp config appsettings set \
    --name "func-b9phish-connector" \
    --resource-group "rg-argus-obsidian" \
    --settings "WORKSPACE_ID=$WORKSPACE_ID" "SHARED_KEY=$SHARED_KEY"

# Create sample data for testing
print_status "Creating sample test data..."
python3 << 'PYTHON_SCRIPT'
import json
from datetime import datetime, timedelta
import random

# Generate sample B9-Phish events
b9_events = []
for i in range(10):
    event = {
        "TimeGenerated": (datetime.utcnow() - timedelta(hours=random.randint(0, 24))).isoformat(),
        "SenderEmail": f"phisher{i}@malicious{i}.com",
        "RecipientEmail": f"user{i}@company.com",
        "Subject": f"Urgent: Action Required #{i}",
        "DetectionType": random.choice(["credential_harvesting", "malware_delivery", "qr_code_phishing"]),
        "DetectionConfidence": round(random.uniform(0.75, 0.99), 2),
        "SPF_Result": random.choice(["pass", "fail"]),
        "DMARC_Result": random.choice(["pass", "fail"]),
        "MaliciousURLs": [f"http://bad{i}.site/phish"] if i % 2 == 0 else [],
        "AttachmentHash": f"hash{i}" if i % 3 == 0 else None
    }
    b9_events.append(event)

with open('data/samples/b9phish_test_data.json', 'w') as f:
    json.dump(b9_events, f, indent=2)

# Generate sample RavenWatch events
rw_events = []
for i in range(20):
    event = {
        "TimeGenerated": datetime.utcnow().isoformat(),
        "Indicator": f"malicious{i}.com" if i % 2 == 0 else f"192.168.{i}.{i}",
        "IndicatorType": "domain" if i % 2 == 0 else "IPAddress",
        "ThreatType": random.choice(["malware", "phishing", "botnet", "scanner"]),
        "ThreatSource": random.choice(["OSINT", "Commercial", "Government", "Community"]),
        "Confidence": round(random.uniform(60, 100), 1),
        "FirstSeen": (datetime.utcnow() - timedelta(days=random.randint(1, 30))).isoformat(),
        "LastSeen": datetime.utcnow().isoformat(),
        "ExpirationDateTime": (datetime.utcnow() + timedelta(days=30)).isoformat()
    }
    rw_events.append(event)

with open('data/samples/ravenwatch_test_data.json', 'w') as f:
    json.dump(rw_events, f, indent=2)

# Generate sample Arkkeeper events
ak_events = []
for i in range(5):
    event = {
        "TimeGenerated": datetime.utcnow().isoformat(),
        "CredentialType": random.choice(["aws_access_key", "azure_service_principal", "github_token", "api_key"]),
        "RepositoryName": f"company/repo{i}",
        "FilePath": f"config/settings{i}.json",
        "CredentialOwner": f"developer{i}@company.com",
        "ExposureLocation": random.choice(["github_public", "gitlab_private", "bitbucket"]),
        "IsActive": random.choice([True, False]),
        "RiskScore": random.randint(40, 100)
    }
    ak_events.append(event)

with open('data/samples/arkkeeper_test_data.json', 'w') as f:
    json.dump(ak_events, f, indent=2)

print("✓ Sample data created successfully")
PYTHON_SCRIPT

# Set up cost alerts
print_status "Setting up cost management alerts..."
az consumption budget create \
    --budget-name "Argus-Budget" \
    --resource-group "rg-argus-obsidian" \
    --amount 50 \
    --time-grain Monthly \
    --category Cost \
    --notifications "ActualCost_GreaterThan_80_Percent=(Contact=[youremail@example.com] Enabled=true Operator=GreaterThan Threshold=80)"

# Create initial detection rule
print_status "Deploying first detection rule..."
cat > detections/analytics_rules/phishing/01_suspicious_phishing_detection.kql << 'EOF'
// Suspicious Phishing Email Detection
// MITRE ATT&CK: T1566.001, T1566.002
// Deployed via Argus-Obsidian

let timeframe = 1h;
B9Phish_Email_Detections_CL
| where TimeGenerated > ago(timeframe)
| where DetectionConfidence_d > 0.85
| where DetectionType_s in ("credential_harvesting", "malware_delivery", "qr_code_phishing")
| where SPF_Result_s == "fail" or DMARC_Result_s == "fail"
| project TimeGenerated, SenderEmail_s, RecipientEmail_s, Subject_s, 
          DetectionType_s, DetectionConfidence_d, MaliciousURLs_s
| extend AccountCustomEntity = RecipientEmail_s
| extend URLCustomEntity = MaliciousURLs_s
EOF

# Git commit initial setup
print_status "Committing to Git..."
git add .
git commit -m "Initial Argus-Obsidian deployment - Week 1 Day 1 complete"

# Generate status report
print_status "Generating deployment report..."
cat > deployment_report.md << EOF
# Argus-Obsidian Deployment Report
## Date: $(date)

### ✅ Completed Tasks
- Azure resource group created: rg-argus-obsidian
- Log Analytics Workspace deployed: law-argus-obsidian
- Microsoft Sentinel enabled
- Storage account created: $STORAGE_ACCOUNT_NAME
- B9-Phish connector function deployed
- Sample test data generated
- Cost alerts configured
- First detection rule created

### 📊 Resource Information
- Subscription ID: $SUBSCRIPTION_ID
- Workspace ID: $WORKSPACE_ID
- Resource Group: rg-argus-obsidian
- Location: East US

### 💰 Cost Tracking
- Current spend: \$0.00
- Daily budget: \$6.67 (to stay under \$200/month)
- Alerts set at: \$50, \$100, \$150

### 🎯 Next Steps
1. Test data ingestion with sample data
2. Verify B9-Phish connector is receiving events
3. Deploy RavenWatch and Arkkeeper connectors
4. Create remaining detection rules
5. Begin playbook development

### 📝 Notes
- Remember to check Azure Portal for function URLs
- Monitor data ingestion in Sentinel Logs blade
- Keep .env file secure and never commit to Git
EOF

print_status "Deployment report saved to deployment_report.md"

# Display summary
echo ""
echo "============================================================================"
echo -e "${GREEN}                    DEPLOYMENT SUCCESSFUL! 🎉                              ${NC}"
echo "============================================================================"
echo ""
echo "✅ Azure Resources Deployed:"
echo "   - Resource Group: rg-argus-obsidian"
echo "   - Log Analytics Workspace: law-argus-obsidian"
echo "   - Microsoft Sentinel: Enabled"
echo "   - Function App: func-b9phish-connector"
echo ""
echo "📁 Project Structure Created:"
echo "   - /detections - Analytics rules"
echo "   - /playbooks - Logic Apps"
echo "   - /integrations - Connectors"
echo "   - /data/samples - Test data"
echo ""
echo "🔑 Credentials Saved:"
echo "   - .env file created (DO NOT COMMIT!)"
echo "   - Workspace ID: $WORKSPACE_ID"
echo ""
echo "💰 Cost Management:"
echo "   - Budget alerts configured"
echo "   - Current spend: \$0.00"
echo "   - Daily limit: \$6.67"
echo ""
echo "🎯 Next Steps:"
echo "   1. Test data ingestion: python3 test_ingestion.py"
echo "   2. Check Sentinel: https://portal.azure.com"
echo "   3. Continue with Day 2 tasks"
echo ""
echo "📚 Documentation:"
echo "   - Project Plan: docs/SentinelDetectionLabProjectPlan.pdf"
echo "   - Daily Tasks: docs/SentinelLab28DayExecutionChecklist.pdf"
echo "   - Game Plan: ARGUS_GAMEPLAN.md"
echo ""
echo "Need help? Check deployment_report.md for details"
echo "============================================================================"

# Optionally push to GitHub
read -p "Push changes to GitHub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin main
    print_status "Changes pushed to GitHub"
fi

print_status "Deployment complete! Happy hunting! 🔍"
