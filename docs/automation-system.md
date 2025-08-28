# NixOS Automation & Workflow Orchestration System

A comprehensive automation platform built on NixOS, providing n8n-like workflow automation capabilities, API orchestration, and system integration tools.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Installation & Setup](#installation--setup)
- [Quick Start](#quick-start)
- [Workflow Engines](#workflow-engines)
- [Development Environment](#development-environment)
- [API Reference](#api-reference)
- [Testing Framework](#testing-framework)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Overview

This automation system provides a complete workflow orchestration platform similar to n8n, Zapier, or Pipedream, but self-hosted and integrated with NixOS. It includes:

- **Multiple workflow engines**: n8n, Node-RED, with support for custom workflows
- **Comprehensive API automation**: HTTP clients, testing tools, and integration capabilities
- **Development environment**: Specialized shells with all necessary tooling
- **Testing framework**: Automated testing for workflows, APIs, and system integration
- **Monitoring & logging**: Real-time workflow monitoring and performance metrics
- **Security**: Built-in authentication, encryption, and access control

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    NixOS Automation System                  │
├─────────────────────────────────────────────────────────────┤
│  Workflow Engines        │  Development Tools               │
│  ┌─────────────────┐     │  ┌─────────────────────────────┐  │
│  │ n8n             │     │  │ Automation Shell            │  │
│  │ Node-RED        │     │  │ - Python ecosystem          │  │
│  │ Custom Runners  │     │  │ - Node.js tools             │  │
│  └─────────────────┘     │  │ - API testing suite         │  │
│                          │  │ - Database clients          │  │
│  API Integration         │  │ - Container tools           │  │
│  ┌─────────────────┐     │  └─────────────────────────────┘  │
│  │ HTTP Clients    │     │                                  │
│  │ WebHooks        │     │  Management & Monitoring         │
│  │ Authentication  │     │  ┌─────────────────────────────┐  │
│  │ Rate Limiting   │     │  │ Test Framework              │  │
│  └─────────────────┘     │  │ System Scripts              │  │
│                          │  │ Health Monitoring           │  │
│  Data Storage            │  │ Performance Metrics         │  │
│  ┌─────────────────┐     │  └─────────────────────────────┘  │
│  │ PostgreSQL      │     │                                  │
│  │ Redis           │     │                                  │
│  │ SQLite          │     │                                  │
│  │ File System     │     │                                  │
│  └─────────────────┘     │                                  │
└─────────────────────────────────────────────────────────────┘
```

## Installation & Setup

### 1. Enable the Automation Module

Add the automation module to your NixOS configuration:

```nix
# /etc/nixos/configuration.nix
{
  imports = [
    # ... other imports
    ./modules/automation-workflow.nix
  ];

  # Enable automation workflow system
  custom.automation-workflow = {
    enable = true;
    
    # Core workflow engines
    engines = {
      n8n = {
        enable = true;
        port = 5678;
        dataDir = "/var/lib/n8n";
      };
      
      nodeRed = {
        enable = true;
        port = 1880;
        userDir = "/var/lib/node-red";
      };
    };
    
    # API automation tools
    api = {
      enable = true;
      tools = {
        postman = true;
        insomnia = true;
        httpie = true;
        jq = true;
        yq = true;
      };
    };
    
    # CLI automation tools
    cli = {
      enable = true;
      tools = {
        github-cli = true;
        aws-cli = true;
        azure-cli = true;
      };
    };
    
    # Integration and messaging
    integration = {
      enable = true;
      messaging.redis = true;
      databases.postgresql = true;
    };
  };
}
```

### 2. Install the Automation Package Collection

Add the automation packages to your system:

```nix
# Include automation packages
environment.systemPackages = with pkgs; [
  (import ./packages/automation-packages.nix { inherit pkgs; })
];
```

### 3. Rebuild the System

```bash
sudo nixos-rebuild switch --flake .#mahmoud-laptop
```

### 4. Start Services

```bash
# Start n8n service
sudo systemctl start n8n
sudo systemctl enable n8n

# Start Node-RED service
sudo systemctl start node-red
sudo systemctl enable node-red

# Check service status
sudo systemctl status n8n node-red
```

## Quick Start

### 1. Access the Automation Environment

Enter the specialized automation development shell:

```bash
nix develop .#automation
```

This provides access to all automation tools, pre-configured environments, and helpful aliases.

### 2. Check System Status

```bash
# Check automation services
automation-health

# Check workflow manager status
workflow-status

# Test API endpoints
api-test http://localhost:5678/healthz
```

### 3. Access Web Interfaces

- **n8n**: http://localhost:5678
- **Node-RED**: http://localhost:1880

### 4. Create Your First Workflow

#### Using the Web Interface (n8n)
1. Open http://localhost:5678 in your browser
2. Create a new workflow
3. Add nodes and connect them
4. Test and save the workflow

#### Using the Command Line
```bash
# Create a sample workflow
workflow-manager.py sample

# Import a workflow from file
workflow-manager.py import /path/to/workflow.json --platform n8n

# Execute a workflow
workflow-manager.py execute workflow_id --data '{"key": "value"}'
```

## Workflow Engines

### n8n

n8n is a powerful workflow automation tool that allows you to connect APIs, databases, and services.

**Key Features:**
- Visual workflow editor
- 200+ integrations
- Custom code nodes
- Webhook support
- Schedule triggers

**Configuration:**
```nix
custom.automation-workflow.engines.n8n = {
  enable = true;
  port = 5678;
  dataDir = "/var/lib/n8n";
  encryptionKey = "your-encryption-key";
};
```

**Usage Examples:**
```bash
# Start n8n
n8n-start

# Check n8n status
curl http://localhost:5678/healthz

# Get workflows via API
curl http://localhost:5678/rest/workflows
```

### Node-RED

Node-RED provides a browser-based editor for wiring together hardware devices, APIs, and online services.

**Key Features:**
- Flow-based programming
- Drag-and-drop interface
- Extensive node library
- Dashboard creation
- IoT integration

**Configuration:**
```nix
custom.automation-workflow.engines.nodeRed = {
  enable = true;
  port = 1880;
  userDir = "/var/lib/node-red";
};
```

**Usage Examples:**
```bash
# Start Node-RED
node-red-start

# Access flows via API
curl http://localhost:1880/flows
```

## Development Environment

### Automation Shell

The automation shell provides a comprehensive development environment:

```bash
# Enter automation shell
nix develop .#automation

# Available tools:
# - Python automation ecosystem
# - Node.js and npm packages
# - API testing tools (curl, httpie, postman)
# - JSON/YAML processors (jq, yq)
# - Database clients (psql, redis-cli)
# - Container tools (docker, kubectl)
# - Cloud CLIs (aws, azure, gcloud)
```

### Key Tools and Aliases

```bash
# HTTP testing
http GET api.example.com/users
curl -s api.example.com/users | jq '.'

# JSON processing
cat data.json | jq '.users[] | .name'
echo '{"name": "test"}' | json

# Workflow management
automation-health                    # System health check
workflow-status                      # Workflow service status
api-test http://localhost:5678      # Test API endpoint

# Docker workflow development
docker-ps                           # Pretty container list
docker-logs container-name          # Follow logs

# Kubernetes automation
k get pods                          # List pods
kgp                                # Alias for kubectl get pods
```

### Python Environment

The shell includes a pre-configured Python environment for automation development:

```python
# Available packages:
import requests      # HTTP library
import asyncio       # Async programming
import aiohttp       # Async HTTP client
import yaml          # YAML processing
import json          # JSON processing
import sqlite3       # Database
import redis         # Caching
import celery        # Task queue
import schedule      # Job scheduling
import click         # CLI development
import rich          # Terminal formatting
```

## API Reference

### System Management Scripts

#### system-automation.sh

```bash
# Health check
./scripts/automation/system-automation.sh health-check

# NixOS configuration management
./scripts/automation/system-automation.sh nixos-manage [--update]

# Service status check
./scripts/automation/system-automation.sh service-check

# Deploy workflow
./scripts/automation/system-automation.sh deploy-workflow /path/to/workflow.json

# Setup monitoring
./scripts/automation/system-automation.sh setup-monitoring

# API testing
./scripts/automation/system-automation.sh api-test "http://localhost:5678/healthz"

# Database backup
./scripts/automation/system-automation.sh db-backup
```

#### workflow-manager.py

```bash
# Check service status
./scripts/automation/workflow-manager.py status

# Import workflow
./scripts/automation/workflow-manager.py import workflow.json --platform n8n

# Execute workflow
./scripts/automation/workflow-manager.py execute workflow_id --data '{"test": "data"}'

# List workflows
./scripts/automation/workflow-manager.py list

# Show execution history
./scripts/automation/workflow-manager.py history workflow_id

# Start monitoring
./scripts/automation/workflow-manager.py monitor --interval 60

# Create sample workflow
./scripts/automation/workflow-manager.py sample
```

## Testing Framework

### Integration Testing

The system includes a comprehensive testing framework:

```bash
# Run all tests
./scripts/automation/test-framework.py --suite all

# Test specific components
./scripts/automation/test-framework.py --suite services
./scripts/automation/test-framework.py --suite api
./scripts/automation/test-framework.py --suite workflows

# Output formats
./scripts/automation/test-framework.py --format json --output results.json
./scripts/automation/test-framework.py --format text --output report.txt
```

### Test Configuration

Create custom test suites:

```yaml
# test-config.yaml
api_tests:
  suite_id: "custom_api_suite"
  name: "Custom API Test Suite"
  description: "Test custom API endpoints"
  tests:
    - endpoint: "https://api.example.com/health"
      method: "GET"
      expected_status: 200
    - endpoint: "https://api.example.com/users"
      method: "POST"
      data: {"name": "test"}
      expected_status: 201
```

### Testing Workflows

```python
# Python test example
from test_framework import WorkflowTester

tester = WorkflowTester()
result = await tester.test_workflow_execution(
    workflow_id="my-workflow",
    input_data={"user_id": 123},
    expected_output={"status": "success"}
)
```

## Examples

### Example 1: API Data Fetcher Workflow

```json
{
  "name": "API Data Fetcher",
  "description": "Fetch data from external API and store in database",
  "nodes": [
    {
      "id": "trigger",
      "type": "n8n-nodes-base.cron",
      "parameters": {
        "triggerTimes": {
          "item": [
            {
              "hour": 9,
              "minute": 0
            }
          ]
        }
      }
    },
    {
      "id": "http_request",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "GET",
        "url": "https://api.example.com/data",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth"
      }
    },
    {
      "id": "postgres",
      "type": "n8n-nodes-base.postgres",
      "parameters": {
        "operation": "insert",
        "table": "api_data",
        "columns": "data,timestamp"
      }
    }
  ]
}
```

### Example 2: System Monitoring Workflow

```javascript
// Node-RED flow for system monitoring
[
  {
    "id": "inject1",
    "type": "inject",
    "name": "Every 5 minutes",
    "props": [],
    "repeat": "300",
    "crontab": "",
    "once": false
  },
  {
    "id": "exec1",
    "type": "exec",
    "command": "df -h / | awk 'NR==2{print $5}'",
    "name": "Check Disk Usage"
  },
  {
    "id": "switch1",
    "type": "switch",
    "name": "Disk Usage > 90%",
    "rules": [
      {
        "t": "gt",
        "v": "90%"
      }
    ]
  },
  {
    "id": "email1",
    "type": "e-mail",
    "name": "Send Alert",
    "server": "smtp.example.com",
    "port": "587"
  }
]
```

### Example 3: Automated Deployment Pipeline

```bash
#!/bin/bash
# deployment-pipeline.sh

# Use automation scripts for CI/CD
set -e

echo "Starting automated deployment pipeline..."

# Health check
./scripts/automation/system-automation.sh health-check

# Run tests
./scripts/automation/test-framework.py --suite all --format json --output test-results.json

# Deploy workflow
if [ -f "workflow.json" ]; then
  ./scripts/automation/workflow-manager.py import workflow.json --platform n8n
fi

# Verify deployment
./scripts/automation/system-automation.sh api-test "http://localhost:5678/healthz"

echo "Deployment pipeline completed successfully!"
```

### Example 4: Database Integration Workflow

```python
# Python script for database automation
import asyncio
from workflow_manager import WorkflowManager

async def database_sync_workflow():
    """Sync data between systems using automation"""
    wm = WorkflowManager()
    
    # Execute data extraction workflow
    extract_result = await wm.execute_workflow(
        "data-extract-workflow",
        input_data={"source": "api", "target": "database"}
    )
    
    if extract_result.status == "completed":
        # Execute transformation workflow
        transform_result = await wm.execute_workflow(
            "data-transform-workflow",
            input_data=extract_result.result
        )
        
        return transform_result
    else:
        raise Exception(f"Extract failed: {extract_result.error}")

# Run the workflow
asyncio.run(database_sync_workflow())
```

## Troubleshooting

### Common Issues

#### n8n Service Not Starting

```bash
# Check service status
sudo systemctl status n8n

# Check logs
sudo journalctl -u n8n -f

# Verify configuration
nixos-option custom.automation-workflow.engines.n8n.enable

# Restart service
sudo systemctl restart n8n
```

#### Node-RED Port Conflict

```bash
# Check if port is in use
sudo netstat -tlnp | grep :1880

# Change port in configuration
# Edit configuration.nix:
custom.automation-workflow.engines.nodeRed.port = 1881;

# Rebuild and restart
sudo nixos-rebuild switch --flake .#mahmoud-laptop
sudo systemctl restart node-red
```

#### Database Connection Issues

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test database connection
psql -U postgres -d n8n -c "\l"

# Reset database
sudo -u postgres psql -c "DROP DATABASE n8n; CREATE DATABASE n8n;"
```

#### Workflow Import Failures

```bash
# Validate JSON format
jq empty workflow.json

# Check workflow format
python3 -c "
import json
with open('workflow.json') as f:
    data = json.load(f)
    print('Valid JSON:', 'nodes' in data and 'connections' in data)
"

# Import with verbose output
./scripts/automation/workflow-manager.py import workflow.json --platform n8n -v
```

### Performance Optimization

#### Resource Monitoring

```bash
# Monitor system resources
htop

# Check automation service memory usage
ps aux | grep -E "(n8n|node-red)" | awk '{print $2, $4, $11}'

# Monitor disk usage
df -h /var/lib/automation

# Check database performance
sudo -u postgres psql -c "
SELECT schemaname,tablename,attname,n_distinct,correlation 
FROM pg_stats WHERE tablename='executions';
"
```

#### Database Optimization

```sql
-- PostgreSQL optimization for n8n
-- Connect as postgres user

-- Analyze execution patterns
ANALYZE;

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_executions_status ON executions(status);
CREATE INDEX IF NOT EXISTS idx_executions_started_at ON executions(started_at);

-- Cleanup old executions (older than 30 days)
DELETE FROM executions WHERE started_at < NOW() - INTERVAL '30 days';

-- Vacuum and reindex
VACUUM ANALYZE;
REINDEX DATABASE n8n;
```

### Debugging Workflows

#### Enable Debug Logging

```bash
# For n8n
export N8N_LOG_LEVEL=debug
sudo systemctl restart n8n

# For Node-RED
# Add to settings.js:
# logging: { console: { level: 'debug' } }
```

#### Workflow Testing

```bash
# Test workflow execution
curl -X POST http://localhost:5678/rest/workflows/WORKFLOW_ID/execute \
  -H "Content-Type: application/json" \
  -d '{"data": {"test": true}}'

# Monitor execution logs
tail -f /var/lib/automation/logs/workflow-manager.log
```

### Security Considerations

#### Enable Authentication

```nix
# Add to configuration.nix
custom.automation-workflow.security = {
  enable = true;
  authentication = {
    oauth2 = true;
    jwt = true;
  };
};
```

#### Secure Secrets Management

```bash
# Use SOPS for secrets
sops secrets/automation.yaml

# Example secrets file:
n8n_encryption_key: "your-secure-key"
database_password: "secure-password"
api_keys:
  github: "ghp_xxxxx"
  slack: "xoxb-xxxxx"
```

For more advanced configuration and troubleshooting, consult the individual tool documentation:
- [n8n Documentation](https://docs.n8n.io)
- [Node-RED Documentation](https://nodered.org/docs/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

---

**Next Steps:**
1. Set up your first workflow using the web interface
2. Explore the automation shell environment
3. Create custom integration scripts
4. Set up monitoring and alerting
5. Implement automated testing for your workflows
