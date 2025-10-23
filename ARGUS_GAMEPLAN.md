# Argus-Obsidian Game Plan 🎯

## Executive Overview
Building a production-grade Microsoft Sentinel Detection Engineering Lab that integrates your existing security tools (B9-Phish, RavenWatch, Arkkeeper) into a unified SIEM/SOAR platform.

**Total Timeline:** 4 weeks (80-100 hours)  
**Daily Commitment:** 3-4 hours  
**Budget:** Stay within Azure $200 free credit

---

## Week 1: Foundation & Data Integration (Days 1-7)
**Focus:** Azure setup, workspace configuration, and custom data connector integration

### Day 1: Azure Environment Setup (4 hours)

#### Morning Session (2 hours)
```bash
# 1. Install Azure CLI on macOS
brew update && brew install azure-cli

# 2. Login to Azure
az login

# 3. Set up cost alerts
az monitor metrics alert create \
  --name "CostAlert50" \
  --resource-group "rg-argus-obsidian" \
  --condition "avg cost > 50" \
  --window-size 1h

# 4. Create resource group
az group create \
  --name "rg-argus-obsidian" \
  --location "eastus"
  
# 5. Save your subscription details
az account show --output json > azure_config.json
```

#### Afternoon Session (2 hours)
```bash
# 1. Deploy Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group "rg-argus-obsidian" \
  --workspace-name "law-argus-obsidian" \
  --location "eastus" \
  --retention-time 31

# 2. Get workspace credentials (SAVE THESE!)
az monitor log-analytics workspace get-shared-keys \
  --resource-group "rg-argus-obsidian" \
  --workspace-name "law-argus-obsidian"

# 3. Enable Sentinel
az sentinel onboarding create \
  --resource-group "rg-argus-obsidian" \
  --workspace-name "law-argus-obsidian" \
  --name "default"

# 4. Initialize your GitHub repo
cd ~/Desktop/Argus-Obsidian
git init
git add .
git commit -m "Day 1: Azure environment setup complete"
git push origin main
```

### Day 2: Architecture & Documentation (3 hours)

```bash
# Create architecture diagram using Python
pip install diagrams

# Create the architecture diagram script
cat > create_architecture.py << 'EOF'
from diagrams import Diagram, Cluster, Edge
from diagrams.azure.analytics import LogAnalyticsWorkspaces
from diagrams.azure.security import Sentinel
from diagrams.azure.compute import FunctionApps
from diagrams.onprem.analytics import Spark

with Diagram("Argus Obsidian Architecture", show=False):
    with Cluster("Microsoft Azure"):
        sentinel = Sentinel("Sentinel SIEM")
        workspace = LogAnalyticsWorkspaces("Log Analytics")
        functions = FunctionApps("Data Connectors")
        
    with Cluster("Security Tools"):
        b9phish = Spark("B9-Phish")
        ravenwatch = Spark("RavenWatch")
        arkkeeper = Spark("Arkkeeper")
    
    [b9phish, ravenwatch, arkkeeper] >> functions >> workspace >> sentinel
EOF

python create_architecture.py

# Update documentation
echo "## Architecture Diagram" >> README.md
echo "![Architecture](argus_obsidian_architecture.png)" >> README.md

git add .
git commit -m "Day 2: Architecture documentation added"
git push
```

### Day 3: Custom Log Tables Design (4 hours)

```bash
# Create table schemas
mkdir -p data/schemas

# B9-Phish schema
cat > data/schemas/b9phish_schema.json << 'EOF'
{
  "name": "B9Phish_Email_Detections_CL",
  "columns": [
    {"name": "TimeGenerated", "type": "datetime"},
    {"name": "SenderEmail", "type": "string"},
    {"name": "RecipientEmail", "type": "string"},
    {"name": "Subject", "type": "string"},
    {"name": "DetectionType", "type": "string"},
    {"name": "DetectionConfidence", "type": "real"},
    {"name": "SPF_Result", "type": "string"},
    {"name": "DMARC_Result", "type": "string"},
    {"name": "MaliciousURLs", "type": "dynamic"},
    {"name": "AttachmentHash", "type": "string"}
  ]
}
EOF

# RavenWatch schema
cat > data/schemas/ravenwatch_schema.json << 'EOF'
{
  "name": "RavenWatch_ThreatIntel_CL",
  "columns": [
    {"name": "TimeGenerated", "type": "datetime"},
    {"name": "Indicator", "type": "string"},
    {"name": "IndicatorType", "type": "string"},
    {"name": "ThreatType", "type": "string"},
    {"name": "ThreatSource", "type": "string"},
    {"name": "Confidence", "type": "real"},
    {"name": "FirstSeen", "type": "datetime"},
    {"name": "LastSeen", "type": "datetime"},
    {"name": "ExpirationDateTime", "type": "datetime"}
  ]
}
EOF

# Arkkeeper schema
cat > data/schemas/arkkeeper_schema.json << 'EOF'
{
  "name": "Arkkeeper_Credentials_CL",
  "columns": [
    {"name": "TimeGenerated", "type": "datetime"},
    {"name": "CredentialType", "type": "string"},
    {"name": "RepositoryName", "type": "string"},
    {"name": "FilePath", "type": "string"},
    {"name": "CredentialOwner", "type": "string"},
    {"name": "ExposureLocation", "type": "string"},
    {"name": "IsActive", "type": "bool"},
    {"name": "RiskScore", "type": "int"}
  ]
}
EOF

# Test data ingestion with Python
python3 integrations/b9-phish/connector/b9phish_connector.py

git add .
git commit -m "Day 3: Custom log table schemas created"
git push
```

### Day 4-5: B9-Phish Integration (8 hours)

```bash
# Day 4: Create Azure Function for B9-Phish
az functionapp create \
  --resource-group "rg-argus-obsidian" \
  --consumption-plan-location "eastus" \
  --runtime python \
  --runtime-version 3.9 \
  --functions-version 4 \
  --name "func-b9phish-connector" \
  --storage-account "saargusdata"

# Deploy function code
cd integrations/b9-phish/connector
func init --python
func new --name B9PhishIngestion --template "HTTP trigger"

# Deploy to Azure
func azure functionapp publish func-b9phish-connector

# Day 5: Test the integration
# Create test script
cat > test_b9phish.py << 'EOF'
import requests
import json
from datetime import datetime

# Function URL
url = "https://func-b9phish-connector.azurewebsites.net/api/B9PhishIngestion"

# Test data
test_events = [
    {
        "TimeGenerated": datetime.utcnow().isoformat(),
        "SenderEmail": "test@phishing.com",
        "RecipientEmail": "victim@company.com",
        "Subject": "Test Phishing Email",
        "DetectionType": "credential_harvesting",
        "DetectionConfidence": 0.95,
        "SPF_Result": "fail",
        "DMARC_Result": "fail",
        "MaliciousURLs": ["http://malicious.site/login"],
        "AttachmentHash": "abc123def456"
    }
]

response = requests.post(url, json=test_events)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
EOF

python test_b9phish.py
```

### Day 6-7: RavenWatch & Arkkeeper Integration (7 hours)

```bash
# Day 6: RavenWatch Integration
az functionapp create \
  --resource-group "rg-argus-obsidian" \
  --consumption-plan-location "eastus" \
  --runtime python \
  --runtime-version 3.9 \
  --functions-version 4 \
  --name "func-ravenwatch-connector" \
  --storage-account "saargusdata"

# Create timer-triggered function for hourly threat intel updates
cd integrations/ravenwatch/connector
func init --python
func new --name RavenWatchSync --template "Timer trigger"

# Day 7: Arkkeeper Integration
az functionapp create \
  --resource-group "rg-argus-obsidian" \
  --consumption-plan-location "eastus" \
  --runtime python \
  --runtime-version 3.9 \
  --functions-version 4 \
  --name "func-arkkeeper-connector" \
  --storage-account "saargusdata"

# Verify all integrations
az monitor log-analytics query \
  --workspace "law-argus-obsidian" \
  --analytics-query "union B9Phish_Email_Detections_CL, RavenWatch_ThreatIntel_CL, Arkkeeper_Credentials_CL | take 10"
```

---

## Week 1 Success Checklist ✅
- [ ] Azure environment deployed
- [ ] Sentinel workspace active
- [ ] GitHub repository structured
- [ ] All 3 data connectors functional
- [ ] Data ingesting successfully
- [ ] Cost tracking < $10
- [ ] Documentation updated

---

## Daily Terminal Commands Cheatsheet

### Start of Each Day
```bash
# Navigate to project
cd ~/Desktop/Argus-Obsidian

# Pull latest changes
git pull

# Check Azure costs
az consumption usage list \
  --start-date 2025-10-22 \
  --end-date 2025-10-29 \
  --query "[].{cost:pretaxCost, name:instanceName}" \
  --output table

# Verify Sentinel health
az monitor log-analytics workspace show \
  --resource-group "rg-argus-obsidian" \
  --workspace-name "law-argus-obsidian" \
  --query "provisioningState"
```

### End of Each Day
```bash
# Commit your work
git add .
git commit -m "Day X: [What you accomplished]"
git push

# Document progress
echo "## Day $(date +%d) Progress" >> docs/daily_log.md
echo "- Tasks completed: [list]" >> docs/daily_log.md
echo "- Blockers: [list]" >> docs/daily_log.md
echo "- Tomorrow's focus: [list]" >> docs/daily_log.md

# Backup critical configs
cp .env ~/Documents/Argus-Backup/.env.$(date +%Y%m%d)
```

---

## Quick Troubleshooting

### If data isn't ingesting:
```bash
# Check function logs
az functionapp logs tail \
  --name "func-b9phish-connector" \
  --resource-group "rg-argus-obsidian"

# Verify workspace key
az monitor log-analytics workspace get-shared-keys \
  --resource-group "rg-argus-obsidian" \
  --workspace-name "law-argus-obsidian"
```

### If costs are climbing:
```bash
# Stop non-essential resources
az functionapp stop \
  --name "func-ravenwatch-connector" \
  --resource-group "rg-argus-obsidian"

# Check data ingestion volume
az monitor metrics list \
  --resource "law-argus-obsidian" \
  --metric "Ingestion Volume" \
  --aggregation Total
```

---

## Week 2-4 Preview

**Week 2-3: Detection Rules & Playbooks**
- Build 15 KQL detection rules
- Create 5 Logic App playbooks
- Test and tune for <5% false positives

**Week 4: Visualization & Launch**
- Create 3 workbooks
- Complete documentation
- Record demo video
- Launch on GitHub

---

## Next Immediate Actions

1. **Right Now:** Run the setup script in your terminal
```bash
cd ~/Desktop/Argus-Obsidian
bash argus_setup.sh
```

2. **Today:** Complete Day 1 Azure setup (4 hours)

3. **This Week:** Focus on data integration - this is the foundation everything else builds on

Remember: Progress over perfection. Ship it! 🚀
