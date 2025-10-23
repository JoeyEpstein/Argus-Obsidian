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
