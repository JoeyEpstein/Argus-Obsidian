#!/bin/bash

# Argus-Obsidian Project Setup Script
# Microsoft Sentinel Detection Engineering Lab
# Run this in your project root directory

echo "🚀 Setting up Argus-Obsidian Project Structure..."

# Create main directory structure
mkdir -p {detections,playbooks,workbooks,docs,scripts,integrations,tests,data}

# Detection rules structure
mkdir -p detections/{analytics_rules,hunting_queries,watchlists}
mkdir -p detections/analytics_rules/{phishing,credential_access,initial_access,persistence,execution}

# Playbooks structure  
mkdir -p playbooks/{phishing_response,credential_compromise,brute_force_mitigation,threat_enrichment,executive_reporting}

# Integration structure for your existing tools
mkdir -p integrations/{b9-phish,ravenwatch,arkkeeper}
mkdir -p integrations/b9-phish/{connector,schemas,samples}
mkdir -p integrations/ravenwatch/{connector,schemas,samples}  
mkdir -p integrations/arkkeeper/{connector,schemas,samples}

# Workbooks structure
mkdir -p workbooks/{executive_dashboard,soc_analyst,detection_health}

# Documentation structure
mkdir -p docs/{deployment,api,detection_logic,architecture}

# Scripts structure
mkdir -p scripts/{azure,data_ingestion,testing,utilities}

# Test data structure
mkdir -p tests/{unit,integration,sample_data}
mkdir -p data/{samples,schemas}

# Create essential markdown files
cat > README.md << 'EOF'
# Argus-Obsidian 🛡️

## Microsoft Sentinel Detection Engineering Lab

A production-grade SIEM/SOAR platform demonstrating enterprise detection engineering capabilities through integration of custom security tools into Microsoft Sentinel.

### 🎯 Project Vision
Build a comprehensive security operations platform that:
- Masters in-demand skills (Sentinel + KQL proficiency)
- Demonstrates integration thinking across security domains
- Proves automation capabilities through SOAR playbooks
- Creates a standout portfolio project

### 📊 Key Metrics
- **15 detection rules** with <5% false positive rate
- **5 automated playbooks** with 95%+ success rate
- **100% MITRE ATT&CK coverage** across 5 tactics
- Query performance <10 seconds, playbook execution <30 seconds

### 🏗️ Architecture
```
┌─────────────────────────────────────────────┐
│            Microsoft Sentinel                │
│  (Analytics Rules + Playbooks + Workbooks)   │
└─────────────────────────────────────────────┘
                      ▲
                      │
       ┌──────────────┼──────────────┐
       │              │              │
┌──────▼────┐  ┌─────▼─────┐  ┌─────▼─────┐
│ B9-Phish  │  │RavenWatch │  │ Arkkeeper │
│  (Email)  │  │(Threat Int)│  │ (Secrets) │
└───────────┘  └───────────┘  └───────────┘
```

### 🚀 Quick Start
1. Clone this repository
2. Follow the [Deployment Guide](docs/deployment/DEPLOYMENT_GUIDE.md)
3. Configure Azure resources using provided templates
4. Deploy detection rules and playbooks
5. Monitor through custom workbooks

### 📁 Project Structure
- `/detections` - KQL analytics rules and hunting queries
- `/playbooks` - Logic App automation workflows
- `/workbooks` - Azure Monitor workbooks
- `/integrations` - Custom tool connectors
- `/docs` - Comprehensive documentation
- `/scripts` - Deployment and utility scripts

### 🛠️ Technologies
- Microsoft Sentinel
- Kusto Query Language (KQL)
- Azure Logic Apps
- Azure Functions
- Python
- MITRE ATT&CK Framework

### 📈 Project Timeline
- **Week 1**: Foundation & Data Integration
- **Week 2-3**: Detection Rules & Playbooks
- **Week 4**: Visualization & Documentation

### 📝 License
[Choose: MIT / Apache 2.0 / Proprietary]

### 🤝 Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### 📧 Contact
[Your Name] - [Your Email]
EOF

cat > CONTRIBUTING.md << 'EOF'
# Contributing to Argus-Obsidian

We welcome contributions! Please follow these guidelines:

## Code Style
- Follow KQL best practices for detection rules
- Comment complex logic
- Test all changes before submitting

## Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Testing
- Include test data for new detection rules
- Validate false positive rates
- Document expected outcomes
EOF

cat > .gitignore << 'EOF'
# Azure credentials and secrets
*.env
.env.local
config/secrets.json
*_keys.json
*.pfx
*.cer

# Azure Function artifacts
bin/
obj/
.python_packages/
.venv/
local.settings.json

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/

# Logs and temporary files
*.log
logs/
temp/
*.tmp

# Test outputs
test-results/
coverage/
*.coverage

# Terraform
*.tfstate
*.tfstate.*
.terraform/
*.tfvars

# Node (for Logic Apps testing)
node_modules/
npm-debug.log*
package-lock.json

# Custom
/data/production/
/backups/
EOF

cat > requirements.txt << 'EOF'
# Python dependencies for integrations
azure-monitor-query>=1.2.0
azure-identity>=1.14.0
azure-keyvault-secrets>=4.7.0
azure-storage-blob>=12.19.0
azure-functions>=1.17.0
requests>=2.31.0
python-dotenv>=1.0.0
pydantic>=2.4.0
pandas>=2.1.0
pytest>=7.4.0
black>=23.9.0
pylint>=3.0.0
EOF

cat > package.json << 'EOF'
{
  "name": "argus-obsidian",
  "version": "1.0.0",
  "description": "Microsoft Sentinel Detection Engineering Lab",
  "scripts": {
    "test": "jest",
    "validate-kql": "node scripts/validate-kql.js",
    "deploy": "sh scripts/deploy.sh"
  },
  "devDependencies": {
    "@azure/arm-logic": "^8.0.0",
    "@azure/identity": "^3.3.0",
    "jest": "^29.7.0"
  }
}
EOF

# Create initial KQL detection rule template
cat > detections/analytics_rules/template_detection_rule.kql << 'EOF'
// Template Detection Rule
// MITRE ATT&CK: [Tactic] - [Technique ID]
// Severity: [High/Medium/Low]
// Description: [Brief description of what this rule detects]

let timeframe = 1h;
let threshold = 5;

// Main detection logic
TableName
| where TimeGenerated > ago(timeframe)
| where [Condition]
| summarize 
    Count = count(),
    FirstSeen = min(TimeGenerated),
    LastSeen = max(TimeGenerated)
    by [GroupByField]
| where Count >= threshold
| extend 
    Severity = case(
        Count > 10, "High",
        Count > 5, "Medium",
        "Low"
    )
| project 
    TimeGenerated = LastSeen,
    Severity,
    Count,
    [GroupByField],
    FirstSeen,
    LastSeen
// Entity mapping
| extend 
    AccountCustomEntity = [UserField],
    IPCustomEntity = [IPField],
    HostCustomEntity = [HostField]
EOF

# Create Azure deployment template
cat > scripts/azure/deploy_sentinel.sh << 'EOF'
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
EOF

# Create Python integration template
cat > integrations/b9-phish/connector/b9phish_connector.py << 'EOF'
"""
B9-Phish to Microsoft Sentinel Connector
Ingests phishing detection events into Log Analytics
"""

import os
import json
import logging
import hashlib
import hmac
import base64
from datetime import datetime
import requests
from typing import Dict, List, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class B9PhishConnector:
    """Connector for B9-Phish to Sentinel integration"""
    
    def __init__(self):
        self.workspace_id = os.environ.get('WORKSPACE_ID')
        self.shared_key = os.environ.get('SHARED_KEY')
        self.log_type = 'B9Phish_Email_Detections'
        self.api_version = '2016-04-01'
        
    def build_signature(self, date: str, content_length: int, 
                        method: str, content_type: str, resource: str) -> str:
        """Build the authorization signature for Log Analytics API"""
        x_headers = f'x-ms-date:{date}'
        string_to_hash = f"{method}\n{content_length}\n{content_type}\n{x_headers}\n{resource}"
        bytes_to_hash = bytes(string_to_hash, encoding="utf-8")
        decoded_key = base64.b64decode(self.shared_key)
        encoded_hash = base64.b64encode(
            hmac.new(decoded_key, bytes_to_hash, digestmod=hashlib.sha256).digest()
        ).decode()
        return f"SharedKey {self.workspace_id}:{encoded_hash}"
    
    def send_to_sentinel(self, events: List[Dict[str, Any]]) -> bool:
        """Send detection events to Sentinel"""
        body = json.dumps(events)
        method = 'POST'
        content_type = 'application/json'
        resource = '/api/logs'
        rfc1123date = datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S GMT')
        content_length = len(body)
        
        signature = self.build_signature(
            rfc1123date, content_length, method, content_type, resource
        )
        
        uri = f"https://{self.workspace_id}.ods.opinsights.azure.com{resource}?api-version={self.api_version}"
        
        headers = {
            'content-type': content_type,
            'Authorization': signature,
            'Log-Type': self.log_type,
            'x-ms-date': rfc1123date
        }
        
        response = requests.post(uri, data=body, headers=headers)
        
        if response.status_code >= 200 and response.status_code <= 299:
            logger.info(f"Successfully sent {len(events)} events to Sentinel")
            return True
        else:
            logger.error(f"Failed to send events. Status: {response.status_code}")
            return False

# Usage example
if __name__ == "__main__":
    connector = B9PhishConnector()
    
    # Sample phishing detection event
    sample_event = {
        "TimeGenerated": datetime.utcnow().isoformat(),
        "SenderEmail": "phisher@malicious.com",
        "RecipientEmail": "user@company.com",
        "Subject": "Urgent: Verify your account",
        "DetectionType": "credential_harvesting",
        "DetectionConfidence": 0.92,
        "SPF_Result": "fail",
        "DMARC_Result": "fail",
        "MaliciousURLs": "http://bit.ly/fake-login",
        "AttachmentHash": None
    }
    
    connector.send_to_sentinel([sample_event])
EOF

# Create environment template
cat > .env.template << 'EOF'
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret

# Log Analytics Workspace
WORKSPACE_ID=your-workspace-id
SHARED_KEY=your-shared-key

# Resource Configuration
RESOURCE_GROUP=rg-argus-obsidian
LOCATION=eastus
WORKSPACE_NAME=law-argus-obsidian

# Integration Keys
B9PHISH_API_KEY=your-b9phish-key
RAVENWATCH_API_KEY=your-ravenwatch-key
ARKKEEPER_API_KEY=your-arkkeeper-key
EOF

# Make scripts executable
chmod +x scripts/azure/deploy_sentinel.sh

echo "✅ Project structure created successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Navigate to your project: cd /path/to/Argus-Obsidian"
echo "2. Initialize git: git add . && git commit -m 'Initial project structure'"
echo "3. Push to GitHub: git push origin main"
echo "4. Copy .env.template to .env and fill in your Azure credentials"
echo "5. Run the deployment script: ./scripts/azure/deploy_sentinel.sh"
echo ""
echo "📚 Reference the 28-Day Execution Checklist for daily tasks!"
