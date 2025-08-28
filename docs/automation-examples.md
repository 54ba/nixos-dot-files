# Automation System Examples & Use Cases

This document provides practical examples and use cases for the NixOS automation system, demonstrating how to leverage n8n-like workflow capabilities for various automation tasks.

## Quick Reference Commands

```bash
# Enter automation development environment
nix develop .#automation

# Check system health
./scripts/automation/system-automation.sh health-check

# Run all integration tests
./scripts/automation/test-framework.py --suite all

# Create and manage workflows
./scripts/automation/workflow-manager.py sample
./scripts/automation/workflow-manager.py status
./scripts/automation/workflow-manager.py list
```

## Example 1: API Data Collection and Processing

### Scenario
Automatically collect data from multiple APIs, process it, and store in a database every hour.

### n8n Workflow Configuration

```json
{
  "name": "Multi-API Data Collector",
  "description": "Collect data from GitHub, weather, and news APIs hourly",
  "nodes": [
    {
      "id": "schedule_trigger",
      "type": "n8n-nodes-base.cron",
      "name": "Hourly Trigger",
      "parameters": {
        "triggerTimes": {
          "item": [{ "hour": "*", "minute": 0 }]
        }
      },
      "position": [100, 100]
    },
    {
      "id": "github_api",
      "type": "n8n-nodes-base.httpRequest", 
      "name": "GitHub API",
      "parameters": {
        "method": "GET",
        "url": "https://api.github.com/repos/owner/repo/commits",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "httpHeaderAuth": {
          "name": "Authorization",
          "value": "token {{$credentials.github.token}}"
        }
      },
      "position": [300, 50]
    },
    {
      "id": "weather_api",
      "type": "n8n-nodes-base.httpRequest",
      "name": "Weather API", 
      "parameters": {
        "method": "GET",
        "url": "https://api.openweathermap.org/data/2.5/weather?q=Cairo&appid={{$credentials.openweather.key}}"
      },
      "position": [300, 150]
    },
    {
      "id": "process_data",
      "type": "n8n-nodes-base.code",
      "name": "Process Data",
      "parameters": {
        "jsCode": `
          const processedData = [];
          
          for (const item of $input.all()) {
            if (item.json.commits) {
              // Process GitHub data
              for (const commit of item.json.commits.slice(0, 5)) {
                processedData.push({
                  type: 'commit',
                  timestamp: new Date().toISOString(),
                  data: {
                    sha: commit.sha,
                    message: commit.commit.message,
                    author: commit.commit.author.name,
                    url: commit.html_url
                  }
                });
              }
            }
            
            if (item.json.weather) {
              // Process weather data
              processedData.push({
                type: 'weather',
                timestamp: new Date().toISOString(),
                data: {
                  temperature: item.json.main.temp,
                  description: item.json.weather[0].description,
                  humidity: item.json.main.humidity,
                  pressure: item.json.main.pressure
                }
              });
            }
          }
          
          return processedData.map(item => ({ json: item }));
        `
      },
      "position": [500, 100]
    },
    {
      "id": "store_database",
      "type": "n8n-nodes-base.postgres",
      "name": "Store in Database",
      "parameters": {
        "operation": "insert",
        "table": "api_data",
        "columns": "type,timestamp,data",
        "values": "={{$json.type}},={{$json.timestamp}},={{JSON.stringify($json.data)}}"
      },
      "position": [700, 100]
    }
  ],
  "connections": {
    "schedule_trigger": {
      "main": [
        [
          { "node": "github_api", "type": "main", "index": 0 },
          { "node": "weather_api", "type": "main", "index": 0 }
        ]
      ]
    },
    "github_api": {
      "main": [
        [{ "node": "process_data", "type": "main", "index": 0 }]
      ]
    },
    "weather_api": {
      "main": [
        [{ "node": "process_data", "type": "main", "index": 0 }]
      ]
    },
    "process_data": {
      "main": [
        [{ "node": "store_database", "type": "main", "index": 0 }]
      ]
    }
  }
}
```

### Setup Instructions

```bash
# 1. Create database table
sudo -u postgres psql -d n8n -c "
CREATE TABLE IF NOT EXISTS api_data (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_api_data_type ON api_data(type);
CREATE INDEX IF NOT EXISTS idx_api_data_timestamp ON api_data(timestamp);
"

# 2. Import the workflow
./scripts/automation/workflow-manager.py import api-collector.json --platform n8n

# 3. Test the workflow
./scripts/automation/workflow-manager.py execute api-collector --data '{}'

# 4. Monitor execution
tail -f /var/lib/automation/logs/workflow-manager.log
```

## Example 2: System Health Monitoring with Alerting

### Scenario
Monitor system resources and send alerts when thresholds are exceeded.

### Node-RED Flow

```javascript
[
  {
    "id": "health_inject",
    "type": "inject",
    "name": "Every 5 minutes",
    "props": [],
    "repeat": "300",
    "crontab": "",
    "once": false,
    "x": 130,
    "y": 100,
    "wires": [["system_check"]]
  },
  {
    "id": "system_check", 
    "type": "exec",
    "name": "System Health Check",
    "command": "/etc/nixos/scripts/automation/system-automation.sh health-check",
    "addpay": false,
    "append": "",
    "useSpawn": "false",
    "x": 320,
    "y": 100,
    "wires": [["parse_health"], [], []]
  },
  {
    "id": "parse_health",
    "type": "function",
    "name": "Parse Health Data",
    "func": `
      try {
        const healthData = JSON.parse(msg.payload);
        
        // Check critical thresholds
        const alerts = [];
        
        if (healthData.system.memory.usage_percent > 90) {
          alerts.push({
            type: 'memory',
            level: 'critical',
            message: 'Memory usage exceeded 90%',
            value: healthData.system.memory.usage_percent
          });
        }
        
        if (parseInt(healthData.system.disk.root_usage.replace('%', '')) > 85) {
          alerts.push({
            type: 'disk',
            level: 'warning', 
            message: 'Disk usage exceeded 85%',
            value: healthData.system.disk.root_usage
          });
        }
        
        if (healthData.system.services.failed > 0) {
          alerts.push({
            type: 'services',
            level: 'error',
            message: healthData.system.services.failed + ' services failed',
            value: healthData.system.services.failed
          });
        }
        
        if (alerts.length > 0) {
          msg.payload = {
            timestamp: new Date().toISOString(),
            hostname: 'mahmoud-laptop',
            alerts: alerts,
            healthData: healthData
          };
          return msg;
        }
        
        return null; // No alerts
      } catch (e) {
        msg.payload = {
          error: 'Failed to parse health data: ' + e.message
        };
        return msg;
      }
    `,
    "x": 520,
    "y": 100,
    "wires": [["alert_switch"]]
  },
  {
    "id": "alert_switch",
    "type": "switch",
    "name": "Alert Level",
    "property": "payload.alerts[0].level",
    "rules": [
      { "t": "eq", "v": "critical" },
      { "t": "eq", "v": "error" },
      { "t": "eq", "v": "warning" }
    ],
    "x": 720,
    "y": 100,
    "wires": [
      ["critical_alert"],
      ["error_alert"], 
      ["warning_alert"]
    ]
  },
  {
    "id": "critical_alert",
    "type": "exec", 
    "name": "Send Critical Alert",
    "command": "notify-send",
    "addpay": true,
    "append": "-u critical 'System Alert' '{{payload.alerts[0].message}}'",
    "x": 950,
    "y": 50,
    "wires": [[], [], []]
  },
  {
    "id": "error_alert",
    "type": "exec",
    "name": "Send Error Alert", 
    "command": "notify-send",
    "addpay": true,
    "append": "-u normal 'System Error' '{{payload.alerts[0].message}}'",
    "x": 950,
    "y": 100,
    "wires": [[], [], []]
  },
  {
    "id": "warning_alert",
    "type": "exec",
    "name": "Send Warning",
    "command": "notify-send", 
    "addpay": true,
    "append": "'System Warning' '{{payload.alerts[0].message}}'",
    "x": 950,
    "y": 150,
    "wires": [[], [], []]
  }
]
```

### Setup Instructions

```bash
# 1. Save the flow to a file
cat > system-monitoring-flow.json << 'EOF'
[...flow JSON above...]
EOF

# 2. Import to Node-RED via API
curl -X POST http://localhost:1880/flows \
  -H "Content-Type: application/json" \
  -d @system-monitoring-flow.json

# 3. Deploy the flows  
curl -X POST http://localhost:1880/flows \
  -H "Content-Type: application/json" \
  -H "Node-RED-Deployment-Type: full"

# 4. Test manual trigger
curl -X POST http://localhost:1880/inject/health_inject
```

## Example 3: Automated Development Workflow

### Scenario
Automate code deployment, testing, and notification processes.

### Python Automation Script

```python
#!/usr/bin/env python3
"""
Development Workflow Automation
Handles git operations, testing, and deployment notifications
"""

import asyncio
import subprocess
import json
import aiohttp
from pathlib import Path
from datetime import datetime

class DevWorkflowAutomation:
    def __init__(self, repo_path="/etc/nixos"):
        self.repo_path = Path(repo_path)
        self.webhook_url = "http://localhost:5678/webhook/deployment"
        
    async def run_tests(self):
        """Run the test framework"""
        try:
            result = subprocess.run([
                "/etc/nixos/scripts/automation/test-framework.py",
                "--suite", "all",
                "--format", "json"
            ], capture_output=True, text=True, cwd=self.repo_path)
            
            if result.returncode == 0:
                return {"status": "passed", "output": result.stdout}
            else:
                return {"status": "failed", "error": result.stderr}
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    async def check_git_changes(self):
        """Check for uncommitted changes"""
        try:
            # Check for uncommitted changes
            result = subprocess.run([
                "git", "status", "--porcelain"
            ], capture_output=True, text=True, cwd=self.repo_path)
            
            has_changes = bool(result.stdout.strip())
            
            # Get last commit info
            commit_result = subprocess.run([
                "git", "log", "-1", "--format=%H|%s|%an|%ad"
            ], capture_output=True, text=True, cwd=self.repo_path)
            
            if commit_result.returncode == 0:
                hash, subject, author, date = commit_result.stdout.strip().split("|", 3)
                last_commit = {
                    "hash": hash[:8],
                    "subject": subject,
                    "author": author,
                    "date": date
                }
            else:
                last_commit = None
            
            return {
                "has_changes": has_changes,
                "last_commit": last_commit,
                "status": "success"
            }
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    async def nixos_build_test(self):
        """Test NixOS configuration build"""
        try:
            result = subprocess.run([
                "nixos-rebuild", "dry-run", "--flake", f"{self.repo_path}#mahmoud-laptop"
            ], capture_output=True, text=True, cwd=self.repo_path)
            
            return {
                "status": "passed" if result.returncode == 0 else "failed",
                "output": result.stdout,
                "error": result.stderr if result.returncode != 0 else None
            }
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    async def send_notification(self, data):
        """Send notification via webhook"""
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(self.webhook_url, json=data) as response:
                    return response.status == 200
        except Exception:
            return False
    
    async def run_full_workflow(self):
        """Run the complete development workflow"""
        workflow_start = datetime.now()
        results = {
            "timestamp": workflow_start.isoformat(),
            "workflow": "development_automation"
        }
        
        print("🚀 Starting development workflow automation...")
        
        # 1. Check git status
        print("📋 Checking git status...")
        git_status = await self.check_git_changes()
        results["git_status"] = git_status
        
        # 2. Run NixOS build test
        print("🔧 Testing NixOS configuration...")
        build_test = await self.nixos_build_test()
        results["build_test"] = build_test
        
        # 3. Run test suite
        print("🧪 Running test suite...")
        test_results = await self.run_tests()
        results["test_results"] = test_results
        
        # 4. Calculate overall status
        all_passed = (
            git_status["status"] == "success" and
            build_test["status"] == "passed" and
            test_results["status"] == "passed"
        )
        
        results["overall_status"] = "passed" if all_passed else "failed"
        results["duration"] = (datetime.now() - workflow_start).total_seconds()
        
        # 5. Send notification
        print("📤 Sending notification...")
        notification_sent = await self.send_notification(results)
        results["notification_sent"] = notification_sent
        
        # 6. Display summary
        print("\n" + "="*50)
        print("DEVELOPMENT WORKFLOW SUMMARY")
        print("="*50)
        print(f"Overall Status: {'✅ PASSED' if all_passed else '❌ FAILED'}")
        print(f"Duration: {results['duration']:.2f}s")
        print(f"Git Changes: {'Yes' if git_status.get('has_changes') else 'No'}")
        print(f"Build Test: {build_test['status'].upper()}")
        print(f"Test Suite: {test_results['status'].upper()}")
        print(f"Notification: {'Sent' if notification_sent else 'Failed'}")
        
        if not all_passed:
            print("\nFAILURES:")
            if build_test["status"] != "passed":
                print(f"  • Build: {build_test.get('error', 'Unknown error')}")
            if test_results["status"] != "passed":
                print(f"  • Tests: {test_results.get('error', 'Unknown error')}")
        
        return results

async def main():
    automation = DevWorkflowAutomation()
    await automation.run_full_workflow()

if __name__ == "__main__":
    asyncio.run(main())
```

### Usage

```bash
# Make the script executable
chmod +x /etc/nixos/scripts/automation/dev-workflow.py

# Run the development workflow
./scripts/automation/dev-workflow.py

# Or integrate with git hooks
# Add to .git/hooks/pre-push:
#!/bin/bash
./scripts/automation/dev-workflow.py
```

## Example 4: API Integration Testing Suite

### Custom Test Configuration

```yaml
# /var/lib/automation/tests/api-integration-tests.yaml
test_suites:
  - name: "Core Services Health Check"
    description: "Test all core automation services"
    tests:
      - name: "n8n Health Check"
        type: "api"
        endpoint: "http://localhost:5678/healthz"
        method: "GET"
        expected_status: 200
        timeout: 10
        
      - name: "Node-RED Status"
        type: "api"
        endpoint: "http://localhost:1880"
        method: "GET"
        expected_status: 200
        timeout: 10
        
      - name: "PostgreSQL Connection"
        type: "database"
        connection: "postgresql://postgres@localhost:5432/n8n"
        query: "SELECT 1 as test"
        expected_result: [{"test": 1}]

  - name: "Workflow API Tests"
    description: "Test workflow management APIs"
    tests:
      - name: "List n8n Workflows"
        type: "api"
        endpoint: "http://localhost:5678/rest/workflows"
        method: "GET"
        expected_status: 200
        headers:
          "Content-Type": "application/json"
        
      - name: "Node-RED Flows"
        type: "api"
        endpoint: "http://localhost:1880/flows"
        method: "GET"
        expected_status: 200
        
      - name: "Create Test Workflow"
        type: "api"
        endpoint: "http://localhost:5678/rest/workflows"
        method: "POST"
        expected_status: 201
        data:
          name: "Test Workflow"
          nodes: []
          connections: {}

  - name: "External API Integration"
    description: "Test external service integrations"
    tests:
      - name: "GitHub API"
        type: "api"
        endpoint: "https://api.github.com/zen"
        method: "GET"
        expected_status: 200
        timeout: 15
        
      - name: "JSONPlaceholder API"
        type: "api"
        endpoint: "https://jsonplaceholder.typicode.com/posts/1"
        method: "GET"
        expected_status: 200
        expected_response:
          userId: 1
          id: 1
```

### Advanced Test Runner

```python
#!/usr/bin/env python3
"""
Advanced API Integration Test Runner
Supports YAML configuration files and custom test types
"""

import yaml
import asyncio
import aiohttp
import psycopg2
import json
import time
from pathlib import Path
from typing import Dict, List, Any

class AdvancedTestRunner:
    def __init__(self, config_file: Path):
        self.config_file = config_file
        self.results = []
        
    async def load_config(self):
        """Load test configuration from YAML file"""
        with open(self.config_file, 'r') as f:
            return yaml.safe_load(f)
    
    async def run_api_test(self, test_config: Dict) -> Dict:
        """Run an API test"""
        start_time = time.time()
        
        try:
            timeout = aiohttp.ClientTimeout(total=test_config.get('timeout', 30))
            async with aiohttp.ClientSession(timeout=timeout) as session:
                method = test_config.get('method', 'GET').upper()
                endpoint = test_config['endpoint']
                headers = test_config.get('headers', {})
                data = test_config.get('data')
                
                async with session.request(
                    method, endpoint, headers=headers, json=data
                ) as response:
                    response_data = await response.text()
                    duration = time.time() - start_time
                    
                    # Check status code
                    expected_status = test_config.get('expected_status', 200)
                    status_ok = response.status == expected_status
                    
                    # Check response content if specified
                    response_ok = True
                    if 'expected_response' in test_config:
                        try:
                            actual_json = json.loads(response_data)
                            expected = test_config['expected_response']
                            response_ok = self._validate_response(actual_json, expected)
                        except json.JSONDecodeError:
                            response_ok = False
                    
                    return {
                        'status': 'passed' if (status_ok and response_ok) else 'failed',
                        'duration': duration,
                        'response_status': response.status,
                        'expected_status': expected_status,
                        'response_size': len(response_data),
                        'error': None if (status_ok and response_ok) else 
                                f"Status: {response.status} (expected {expected_status})" +
                                ("" if response_ok else " | Response validation failed")
                    }
        except Exception as e:
            return {
                'status': 'error',
                'duration': time.time() - start_time,
                'error': str(e)
            }
    
    async def run_database_test(self, test_config: Dict) -> Dict:
        """Run a database test"""
        start_time = time.time()
        
        try:
            conn = psycopg2.connect(test_config['connection'])
            cursor = conn.cursor()
            cursor.execute(test_config['query'])
            
            if 'expected_result' in test_config:
                result = cursor.fetchall()
                columns = [desc[0] for desc in cursor.description]
                result_dicts = [dict(zip(columns, row)) for row in result]
                
                expected = test_config['expected_result']
                results_match = result_dicts == expected
                
                cursor.close()
                conn.close()
                
                return {
                    'status': 'passed' if results_match else 'failed',
                    'duration': time.time() - start_time,
                    'result': result_dicts,
                    'expected': expected,
                    'error': None if results_match else 'Result mismatch'
                }
            else:
                cursor.close()
                conn.close()
                
                return {
                    'status': 'passed',
                    'duration': time.time() - start_time,
                    'error': None
                }
                
        except Exception as e:
            return {
                'status': 'error',
                'duration': time.time() - start_time,
                'error': str(e)
            }
    
    def _validate_response(self, actual: Any, expected: Any) -> bool:
        """Validate API response against expected values"""
        if isinstance(expected, dict):
            if not isinstance(actual, dict):
                return False
            for key, value in expected.items():
                if key not in actual:
                    return False
                if not self._validate_response(actual[key], value):
                    return False
            return True
        elif isinstance(expected, list):
            if not isinstance(actual, list) or len(actual) != len(expected):
                return False
            return all(self._validate_response(a, e) for a, e in zip(actual, expected))
        else:
            return actual == expected
    
    async def run_test_suite(self, suite_config: Dict) -> Dict:
        """Run a complete test suite"""
        suite_start = time.time()
        test_results = []
        
        print(f"\n🧪 Running suite: {suite_config['name']}")
        print(f"   {suite_config.get('description', '')}")
        
        for test_config in suite_config.get('tests', []):
            print(f"   • {test_config['name']}... ", end="")
            
            test_type = test_config.get('type', 'api')
            
            if test_type == 'api':
                result = await self.run_api_test(test_config)
            elif test_type == 'database':
                result = await self.run_database_test(test_config)
            else:
                result = {
                    'status': 'error',
                    'duration': 0,
                    'error': f'Unknown test type: {test_type}'
                }
            
            result['name'] = test_config['name']
            result['type'] = test_type
            test_results.append(result)
            
            # Print result
            if result['status'] == 'passed':
                print(f"✅ ({result['duration']:.2f}s)")
            elif result['status'] == 'failed':
                print(f"❌ ({result['duration']:.2f}s)")
            else:
                print(f"💥 ({result['duration']:.2f}s)")
        
        # Calculate suite statistics
        total_tests = len(test_results)
        passed_tests = len([r for r in test_results if r['status'] == 'passed'])
        failed_tests = len([r for r in test_results if r['status'] == 'failed'])
        error_tests = len([r for r in test_results if r['status'] == 'error'])
        success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
        total_duration = time.time() - suite_start
        
        return {
            'name': suite_config['name'],
            'description': suite_config.get('description', ''),
            'total_tests': total_tests,
            'passed_tests': passed_tests,
            'failed_tests': failed_tests,
            'error_tests': error_tests,
            'success_rate': success_rate,
            'total_duration': total_duration,
            'tests': test_results
        }
    
    async def run_all_suites(self):
        """Run all test suites from configuration"""
        config = await self.load_config()
        
        print("🚀 Starting Advanced API Integration Tests")
        print("=" * 50)
        
        all_results = []
        
        for suite_config in config.get('test_suites', []):
            suite_result = await self.run_test_suite(suite_config)
            all_results.append(suite_result)
        
        # Print summary
        print("\n" + "=" * 50)
        print("TEST SUMMARY")
        print("=" * 50)
        
        total_suites = len(all_results)
        total_tests = sum(r['total_tests'] for r in all_results)
        total_passed = sum(r['passed_tests'] for r in all_results)
        total_failed = sum(r['failed_tests'] for r in all_results)
        total_errors = sum(r['error_tests'] for r in all_results)
        overall_success_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
        
        print(f"Suites: {total_suites}")
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {total_passed}")
        print(f"Failed: {total_failed}")
        print(f"Errors: {total_errors}")
        print(f"Success Rate: {overall_success_rate:.1f}%")
        
        # Print failed tests details
        failed_tests = []
        for suite in all_results:
            for test in suite['tests']:
                if test['status'] in ['failed', 'error']:
                    failed_tests.append(f"{suite['name']}: {test['name']} - {test['error']}")
        
        if failed_tests:
            print(f"\nFAILED TESTS:")
            for failure in failed_tests:
                print(f"  • {failure}")
        
        return all_results

async def main():
    config_file = Path("/var/lib/automation/tests/api-integration-tests.yaml")
    
    if not config_file.exists():
        print(f"Configuration file not found: {config_file}")
        print("Creating sample configuration...")
        
        # Create sample config (truncated for brevity)
        sample_config = {
            'test_suites': [
                {
                    'name': 'Basic Health Checks',
                    'description': 'Test basic service availability',
                    'tests': [
                        {
                            'name': 'Local n8n Health',
                            'type': 'api',
                            'endpoint': 'http://localhost:5678/healthz',
                            'method': 'GET',
                            'expected_status': 200,
                            'timeout': 10
                        }
                    ]
                }
            ]
        }
        
        config_file.parent.mkdir(parents=True, exist_ok=True)
        with open(config_file, 'w') as f:
            yaml.dump(sample_config, f, default_flow_style=False)
        
        print(f"Sample configuration created at {config_file}")
        print("Edit the configuration and run again.")
        return
    
    runner = AdvancedTestRunner(config_file)
    results = await runner.run_all_suites()
    
    # Save results
    results_file = Path("/var/lib/automation/test-results") / f"advanced-tests-{int(time.time())}.json"
    results_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"\nDetailed results saved to: {results_file}")

if __name__ == "__main__":
    asyncio.run(main())
```

Save this as `/etc/nixos/scripts/automation/advanced-test-runner.py` and make it executable:

```bash
chmod +x /etc/nixos/scripts/automation/advanced-test-runner.py
```

## Integration with Configuration

Now let's add the automation module to your main configuration and test it:

<function_calls>
<invoke name="edit_files">
<parameter name="title">Add automation workflow module to main configuration
