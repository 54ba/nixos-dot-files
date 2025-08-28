#!/usr/bin/env python3
"""
Workflow Manager - Python-based automation script
Provides advanced workflow management and API automation capabilities
Compatible with n8n, Node-RED, and other automation platforms
"""

import json
import os
import sys
import requests
import subprocess
import logging
import yaml
import sqlite3
import argparse
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any
import asyncio
import aiohttp
from dataclasses import dataclass, asdict

# Configuration
AUTOMATION_DIR = Path("/var/lib/automation")
LOG_DIR = AUTOMATION_DIR / "logs"
CONFIG_DIR = AUTOMATION_DIR / "config"
WORKFLOWS_DIR = AUTOMATION_DIR / "workflows"
DB_PATH = AUTOMATION_DIR / "workflows.db"

# Ensure directories exist
for directory in [AUTOMATION_DIR, LOG_DIR, CONFIG_DIR, WORKFLOWS_DIR]:
    directory.mkdir(parents=True, exist_ok=True)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / "workflow-manager.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class WorkflowExecution:
    """Represents a workflow execution instance"""
    id: str
    workflow_id: str
    status: str
    start_time: datetime
    end_time: Optional[datetime] = None
    result: Optional[Dict] = None
    error: Optional[str] = None

class WorkflowDatabase:
    """SQLite database for managing workflow metadata"""
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize database tables"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS workflows (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    platform TEXT,
                    config TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS executions (
                    id TEXT PRIMARY KEY,
                    workflow_id TEXT,
                    status TEXT,
                    start_time TIMESTAMP,
                    end_time TIMESTAMP,
                    result TEXT,
                    error TEXT,
                    FOREIGN KEY (workflow_id) REFERENCES workflows (id)
                )
            """)
            
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_executions_workflow 
                ON executions(workflow_id)
            """)
            
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_executions_status 
                ON executions(status)
            """)
    
    def save_workflow(self, workflow_id: str, name: str, description: str, 
                     platform: str, config: Dict):
        """Save workflow metadata"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO workflows 
                (id, name, description, platform, config, updated_at)
                VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            """, (workflow_id, name, description, platform, json.dumps(config)))
    
    def save_execution(self, execution: WorkflowExecution):
        """Save workflow execution record"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO executions 
                (id, workflow_id, status, start_time, end_time, result, error)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                execution.id,
                execution.workflow_id,
                execution.status,
                execution.start_time,
                execution.end_time,
                json.dumps(execution.result) if execution.result else None,
                execution.error
            ))
    
    def get_workflows(self) -> List[Dict]:
        """Get all workflows"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("SELECT * FROM workflows ORDER BY updated_at DESC")
            return [dict(row) for row in cursor.fetchall()]
    
    def get_workflow_executions(self, workflow_id: str, limit: int = 50) -> List[Dict]:
        """Get execution history for a workflow"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM executions 
                WHERE workflow_id = ? 
                ORDER BY start_time DESC 
                LIMIT ?
            """, (workflow_id, limit))
            return [dict(row) for row in cursor.fetchall()]

class N8NManager:
    """Manager for n8n workflow automation platform"""
    
    def __init__(self, base_url: str = "http://localhost:5678"):
        self.base_url = base_url
        self.session = requests.Session()
    
    def health_check(self) -> bool:
        """Check if n8n is accessible"""
        try:
            response = self.session.get(f"{self.base_url}/healthz", timeout=5)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def get_workflows(self) -> List[Dict]:
        """Get all workflows from n8n"""
        try:
            response = self.session.get(f"{self.base_url}/rest/workflows")
            response.raise_for_status()
            return response.json().get("data", [])
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get n8n workflows: {e}")
            return []
    
    def execute_workflow(self, workflow_id: str, data: Optional[Dict] = None) -> Dict:
        """Execute a workflow in n8n"""
        try:
            url = f"{self.base_url}/rest/workflows/{workflow_id}/execute"
            payload = {"data": data or {}}
            response = self.session.post(url, json=payload)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to execute n8n workflow {workflow_id}: {e}")
            raise
    
    def import_workflow(self, workflow_data: Dict) -> str:
        """Import workflow to n8n"""
        try:
            response = self.session.post(
                f"{self.base_url}/rest/workflows",
                json=workflow_data
            )
            response.raise_for_status()
            return response.json().get("data", {}).get("id")
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to import workflow to n8n: {e}")
            raise

class NodeREDManager:
    """Manager for Node-RED visual programming environment"""
    
    def __init__(self, base_url: str = "http://localhost:1880"):
        self.base_url = base_url
        self.session = requests.Session()
    
    def health_check(self) -> bool:
        """Check if Node-RED is accessible"""
        try:
            response = self.session.get(f"{self.base_url}/", timeout=5)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def get_flows(self) -> List[Dict]:
        """Get all flows from Node-RED"""
        try:
            response = self.session.get(f"{self.base_url}/flows")
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get Node-RED flows: {e}")
            return []
    
    def deploy_flow(self, flow_data: List[Dict]) -> bool:
        """Deploy flow to Node-RED"""
        try:
            response = self.session.post(
                f"{self.base_url}/flows",
                json=flow_data,
                headers={"Content-Type": "application/json"}
            )
            response.raise_for_status()
            return True
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to deploy flow to Node-RED: {e}")
            return False

class WorkflowManager:
    """Main workflow management class"""
    
    def __init__(self):
        self.db = WorkflowDatabase(DB_PATH)
        self.n8n = N8NManager()
        self.node_red = NodeREDManager()
    
    def check_services(self) -> Dict[str, bool]:
        """Check status of automation services"""
        services = {
            "n8n": self.n8n.health_check(),
            "node-red": self.node_red.health_check(),
            "postgresql": self._check_postgresql(),
            "redis": self._check_redis()
        }
        
        for service, status in services.items():
            if status:
                logger.info(f"✓ {service} is running")
            else:
                logger.warning(f"✗ {service} is not accessible")
        
        return services
    
    def _check_postgresql(self) -> bool:
        """Check PostgreSQL service"""
        try:
            result = subprocess.run(
                ["systemctl", "is-active", "postgresql"],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except subprocess.SubprocessError:
            return False
    
    def _check_redis(self) -> bool:
        """Check Redis service"""
        try:
            result = subprocess.run(
                ["systemctl", "is-active", "redis"],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except subprocess.SubprocessError:
            return False
    
    def import_workflow_file(self, file_path: Path, platform: str = "auto") -> str:
        """Import workflow from file"""
        logger.info(f"Importing workflow from {file_path}")
        
        if not file_path.exists():
            raise FileNotFoundError(f"Workflow file not found: {file_path}")
        
        # Read workflow file
        with open(file_path, 'r') as f:
            if file_path.suffix.lower() == '.json':
                workflow_data = json.load(f)
            elif file_path.suffix.lower() in ['.yaml', '.yml']:
                workflow_data = yaml.safe_load(f)
            else:
                raise ValueError(f"Unsupported file format: {file_path.suffix}")
        
        # Auto-detect platform if needed
        if platform == "auto":
            platform = self._detect_workflow_platform(workflow_data)
        
        # Generate workflow ID
        workflow_id = f"{platform}_{file_path.stem}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        # Import to appropriate platform
        if platform == "n8n" and self.n8n.health_check():
            try:
                imported_id = self.n8n.import_workflow(workflow_data)
                workflow_id = imported_id or workflow_id
                logger.info(f"Successfully imported to n8n with ID: {workflow_id}")
            except Exception as e:
                logger.error(f"Failed to import to n8n: {e}")
                raise
        
        elif platform == "node-red" and self.node_red.health_check():
            try:
                success = self.node_red.deploy_flow(workflow_data)
                if success:
                    logger.info(f"Successfully deployed to Node-RED")
                else:
                    raise Exception("Failed to deploy to Node-RED")
            except Exception as e:
                logger.error(f"Failed to deploy to Node-RED: {e}")
                raise
        
        # Save workflow metadata
        self.db.save_workflow(
            workflow_id=workflow_id,
            name=workflow_data.get("name", file_path.stem),
            description=workflow_data.get("description", ""),
            platform=platform,
            config=workflow_data
        )
        
        logger.info(f"Workflow imported successfully with ID: {workflow_id}")
        return workflow_id
    
    def _detect_workflow_platform(self, workflow_data: Dict) -> str:
        """Auto-detect workflow platform based on structure"""
        if "nodes" in workflow_data and "connections" in workflow_data:
            return "n8n"
        elif isinstance(workflow_data, list) and any("type" in item for item in workflow_data):
            return "node-red"
        else:
            return "generic"
    
    def execute_workflow(self, workflow_id: str, input_data: Optional[Dict] = None) -> WorkflowExecution:
        """Execute a workflow"""
        execution = WorkflowExecution(
            id=f"exec_{workflow_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            workflow_id=workflow_id,
            status="running",
            start_time=datetime.now()
        )
        
        try:
            logger.info(f"Executing workflow: {workflow_id}")
            
            # Get workflow info
            workflows = [w for w in self.db.get_workflows() if w["id"] == workflow_id]
            if not workflows:
                raise ValueError(f"Workflow not found: {workflow_id}")
            
            workflow = workflows[0]
            platform = workflow["platform"]
            
            # Execute based on platform
            if platform == "n8n":
                result = self.n8n.execute_workflow(workflow_id, input_data)
            else:
                raise ValueError(f"Execution not supported for platform: {platform}")
            
            execution.status = "completed"
            execution.end_time = datetime.now()
            execution.result = result
            
            logger.info(f"Workflow {workflow_id} executed successfully")
            
        except Exception as e:
            execution.status = "failed"
            execution.end_time = datetime.now()
            execution.error = str(e)
            logger.error(f"Workflow {workflow_id} execution failed: {e}")
        
        # Save execution record
        self.db.save_execution(execution)
        return execution
    
    def list_workflows(self) -> List[Dict]:
        """List all workflows"""
        return self.db.get_workflows()
    
    def get_workflow_history(self, workflow_id: str) -> List[Dict]:
        """Get execution history for a workflow"""
        return self.db.get_workflow_executions(workflow_id)
    
    async def monitor_workflows(self, interval: int = 60):
        """Monitor workflow health and performance"""
        logger.info(f"Starting workflow monitoring (interval: {interval}s)")
        
        while True:
            try:
                # Check service health
                services = self.check_services()
                
                # Get workflow statistics
                workflows = self.list_workflows()
                total_workflows = len(workflows)
                
                # Check recent executions
                recent_executions = []
                for workflow in workflows:
                    executions = self.get_workflow_history(workflow["id"], limit=10)
                    recent_executions.extend(executions)
                
                # Calculate success rate
                if recent_executions:
                    successful = len([e for e in recent_executions if e["status"] == "completed"])
                    success_rate = (successful / len(recent_executions)) * 100
                else:
                    success_rate = 0
                
                # Log monitoring report
                report = {
                    "timestamp": datetime.now().isoformat(),
                    "services": services,
                    "workflows": {
                        "total": total_workflows,
                        "recent_executions": len(recent_executions),
                        "success_rate": success_rate
                    }
                }
                
                logger.info(f"Monitoring report: {json.dumps(report, indent=2)}")
                
                # Save monitoring report
                report_file = LOG_DIR / f"monitoring-{datetime.now().strftime('%Y%m%d')}.json"
                with open(report_file, 'a') as f:
                    f.write(json.dumps(report) + "\n")
                
            except Exception as e:
                logger.error(f"Error in workflow monitoring: {e}")
            
            await asyncio.sleep(interval)

def create_sample_workflow():
    """Create a sample n8n workflow for testing"""
    workflow = {
        "name": "System Health Check Workflow",
        "description": "Automated system health monitoring workflow",
        "nodes": [
            {
                "id": "start",
                "type": "n8n-nodes-base.start",
                "position": [100, 100],
                "parameters": {}
            },
            {
                "id": "http_request",
                "type": "n8n-nodes-base.httpRequest",
                "position": [300, 100],
                "parameters": {
                    "method": "GET",
                    "url": "http://localhost:8080/health"
                }
            },
            {
                "id": "set_data",
                "type": "n8n-nodes-base.set",
                "position": [500, 100],
                "parameters": {
                    "values": {
                        "string": [
                            {
                                "name": "status",
                                "value": "={{$json.status}}"
                            }
                        ]
                    }
                }
            }
        ],
        "connections": {
            "start": {
                "main": [
                    [
                        {"node": "http_request", "type": "main", "index": 0}
                    ]
                ]
            },
            "http_request": {
                "main": [
                    [
                        {"node": "set_data", "type": "main", "index": 0}
                    ]
                ]
            }
        }
    }
    
    # Save sample workflow
    sample_file = WORKFLOWS_DIR / "sample_health_check.json"
    with open(sample_file, 'w') as f:
        json.dump(workflow, f, indent=2)
    
    logger.info(f"Sample workflow created: {sample_file}")
    return sample_file

def main():
    """Main CLI interface"""
    parser = argparse.ArgumentParser(description="Workflow Manager - Automation Platform")
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Status command
    status_parser = subparsers.add_parser('status', help='Check services status')
    
    # Import command
    import_parser = subparsers.add_parser('import', help='Import workflow from file')
    import_parser.add_argument('file', help='Workflow file path')
    import_parser.add_argument('--platform', choices=['n8n', 'node-red', 'auto'], 
                              default='auto', help='Target platform')
    
    # Execute command
    execute_parser = subparsers.add_parser('execute', help='Execute workflow')
    execute_parser.add_argument('workflow_id', help='Workflow ID')
    execute_parser.add_argument('--data', help='Input data as JSON string')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List workflows')
    
    # History command
    history_parser = subparsers.add_parser('history', help='Show workflow execution history')
    history_parser.add_argument('workflow_id', help='Workflow ID')
    
    # Monitor command
    monitor_parser = subparsers.add_parser('monitor', help='Start workflow monitoring')
    monitor_parser.add_argument('--interval', type=int, default=60, 
                               help='Monitoring interval in seconds')
    
    # Sample command
    sample_parser = subparsers.add_parser('sample', help='Create sample workflow')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    # Initialize workflow manager
    wm = WorkflowManager()
    
    try:
        if args.command == 'status':
            services = wm.check_services()
            print(f"Service Status: {json.dumps(services, indent=2)}")
        
        elif args.command == 'import':
            workflow_id = wm.import_workflow_file(Path(args.file), args.platform)
            print(f"Workflow imported with ID: {workflow_id}")
        
        elif args.command == 'execute':
            input_data = json.loads(args.data) if args.data else None
            execution = wm.execute_workflow(args.workflow_id, input_data)
            print(f"Execution result: {json.dumps(asdict(execution), indent=2, default=str)}")
        
        elif args.command == 'list':
            workflows = wm.list_workflows()
            print(f"Workflows: {json.dumps(workflows, indent=2)}")
        
        elif args.command == 'history':
            history = wm.get_workflow_history(args.workflow_id)
            print(f"Execution History: {json.dumps(history, indent=2)}")
        
        elif args.command == 'monitor':
            asyncio.run(wm.monitor_workflows(args.interval))
        
        elif args.command == 'sample':
            sample_file = create_sample_workflow()
            print(f"Sample workflow created: {sample_file}")
    
    except Exception as e:
        logger.error(f"Command failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
