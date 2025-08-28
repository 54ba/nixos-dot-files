#!/usr/bin/env python3
"""
Automation Integration Testing Framework
Provides comprehensive testing capabilities for automation workflows,
API endpoints, system integration, and service validation.
"""

import json
import sys
import time
import requests
import subprocess
import asyncio
import aiohttp
import sqlite3
import logging
import yaml
import os
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from concurrent.futures import ThreadPoolExecutor, as_completed
import unittest
import pytest

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
TEST_DATA_DIR = Path("/var/lib/automation/tests")
TEST_RESULTS_DIR = Path("/var/lib/automation/test-results")
WORKFLOWS_DIR = Path("/var/lib/automation/workflows")

# Ensure directories exist
for directory in [TEST_DATA_DIR, TEST_RESULTS_DIR, WORKFLOWS_DIR]:
    directory.mkdir(parents=True, exist_ok=True)

@dataclass
class TestResult:
    """Represents the result of a single test"""
    test_id: str
    test_name: str
    test_type: str
    status: str  # passed, failed, skipped, error
    duration: float
    timestamp: datetime
    details: Optional[Dict] = None
    error_message: Optional[str] = None
    logs: Optional[List[str]] = None

@dataclass
class TestSuite:
    """Represents a collection of related tests"""
    suite_id: str
    suite_name: str
    description: str
    tests: List[TestResult]
    total_tests: int
    passed_tests: int
    failed_tests: int
    skipped_tests: int
    error_tests: int
    total_duration: float
    success_rate: float

class APITester:
    """API endpoint testing functionality"""
    
    def __init__(self, base_url: str = None, timeout: int = 30):
        self.base_url = base_url
        self.timeout = timeout
        self.session = requests.Session()
    
    async def test_endpoint(self, endpoint: str, method: str = "GET", 
                           headers: Dict = None, data: Any = None,
                           expected_status: int = 200,
                           expected_response: Dict = None) -> TestResult:
        """Test a single API endpoint"""
        test_id = f"api_{method.lower()}_{endpoint.replace('/', '_').replace(':', '_')}"
        start_time = time.time()
        
        try:
            url = f"{self.base_url}{endpoint}" if self.base_url else endpoint
            
            # Make the request
            response = self.session.request(
                method=method,
                url=url,
                headers=headers or {},
                json=data if isinstance(data, dict) else None,
                data=data if not isinstance(data, dict) else None,
                timeout=self.timeout
            )
            
            duration = time.time() - start_time
            
            # Check status code
            status_ok = response.status_code == expected_status
            
            # Check response content if expected
            response_ok = True
            if expected_response:
                try:
                    actual_response = response.json()
                    response_ok = self._compare_responses(actual_response, expected_response)
                except ValueError:
                    response_ok = False
            
            # Determine test result
            if status_ok and response_ok:
                status = "passed"
                error_message = None
            else:
                status = "failed"
                error_message = f"Expected status {expected_status}, got {response.status_code}"
                if not response_ok:
                    error_message += f" | Response mismatch"
            
            return TestResult(
                test_id=test_id,
                test_name=f"{method} {endpoint}",
                test_type="api",
                status=status,
                duration=duration,
                timestamp=datetime.now(),
                details={
                    "endpoint": endpoint,
                    "method": method,
                    "expected_status": expected_status,
                    "actual_status": response.status_code,
                    "response_time": duration,
                    "response_size": len(response.content),
                    "headers": dict(response.headers)
                },
                error_message=error_message
            )
            
        except requests.exceptions.RequestException as e:
            duration = time.time() - start_time
            return TestResult(
                test_id=test_id,
                test_name=f"{method} {endpoint}",
                test_type="api",
                status="error",
                duration=duration,
                timestamp=datetime.now(),
                error_message=str(e)
            )
    
    def _compare_responses(self, actual: Dict, expected: Dict) -> bool:
        """Compare API responses for testing"""
        try:
            for key, value in expected.items():
                if key not in actual:
                    return False
                if isinstance(value, dict):
                    if not self._compare_responses(actual[key], value):
                        return False
                elif actual[key] != value:
                    return False
            return True
        except (KeyError, TypeError):
            return False
    
    async def test_api_suite(self, test_config: Dict) -> TestSuite:
        """Run a complete API test suite"""
        suite_id = test_config.get("suite_id", "api_suite")
        suite_name = test_config.get("name", "API Test Suite")
        description = test_config.get("description", "")
        
        tests = []
        start_time = time.time()
        
        for test_case in test_config.get("tests", []):
            result = await self.test_endpoint(**test_case)
            tests.append(result)
        
        total_duration = time.time() - start_time
        
        # Calculate statistics
        total_tests = len(tests)
        passed_tests = len([t for t in tests if t.status == "passed"])
        failed_tests = len([t for t in tests if t.status == "failed"])
        skipped_tests = len([t for t in tests if t.status == "skipped"])
        error_tests = len([t for t in tests if t.status == "error"])
        success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
        
        return TestSuite(
            suite_id=suite_id,
            suite_name=suite_name,
            description=description,
            tests=tests,
            total_tests=total_tests,
            passed_tests=passed_tests,
            failed_tests=failed_tests,
            skipped_tests=skipped_tests,
            error_tests=error_tests,
            total_duration=total_duration,
            success_rate=success_rate
        )

class WorkflowTester:
    """Workflow execution and validation testing"""
    
    def __init__(self):
        self.n8n_base_url = "http://localhost:5678"
        self.node_red_base_url = "http://localhost:1880"
    
    async def test_workflow_execution(self, workflow_id: str, 
                                    input_data: Dict = None,
                                    expected_output: Dict = None,
                                    timeout: int = 60) -> TestResult:
        """Test workflow execution"""
        test_id = f"workflow_{workflow_id}"
        start_time = time.time()
        
        try:
            # Execute workflow (assuming n8n for now)
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=timeout)) as session:
                url = f"{self.n8n_base_url}/rest/workflows/{workflow_id}/execute"
                payload = {"data": input_data or {}}
                
                async with session.post(url, json=payload) as response:
                    duration = time.time() - start_time
                    
                    if response.status == 200:
                        result_data = await response.json()
                        
                        # Validate output if expected
                        output_valid = True
                        if expected_output:
                            output_valid = self._validate_workflow_output(
                                result_data, expected_output
                            )
                        
                        status = "passed" if output_valid else "failed"
                        error_message = None if output_valid else "Output validation failed"
                        
                        return TestResult(
                            test_id=test_id,
                            test_name=f"Workflow {workflow_id}",
                            test_type="workflow",
                            status=status,
                            duration=duration,
                            timestamp=datetime.now(),
                            details={
                                "workflow_id": workflow_id,
                                "input_data": input_data,
                                "output_data": result_data,
                                "execution_time": duration
                            },
                            error_message=error_message
                        )
                    else:
                        error_text = await response.text()
                        return TestResult(
                            test_id=test_id,
                            test_name=f"Workflow {workflow_id}",
                            test_type="workflow",
                            status="failed",
                            duration=duration,
                            timestamp=datetime.now(),
                            error_message=f"HTTP {response.status}: {error_text}"
                        )
                        
        except asyncio.TimeoutError:
            duration = time.time() - start_time
            return TestResult(
                test_id=test_id,
                test_name=f"Workflow {workflow_id}",
                test_type="workflow",
                status="error",
                duration=duration,
                timestamp=datetime.now(),
                error_message="Execution timeout"
            )
        except Exception as e:
            duration = time.time() - start_time
            return TestResult(
                test_id=test_id,
                test_name=f"Workflow {workflow_id}",
                test_type="workflow",
                status="error",
                duration=duration,
                timestamp=datetime.now(),
                error_message=str(e)
            )
    
    def _validate_workflow_output(self, actual: Dict, expected: Dict) -> bool:
        """Validate workflow output against expected results"""
        try:
            # This is a simplified validation - can be extended
            for key, value in expected.items():
                if key not in actual:
                    return False
                if isinstance(value, dict):
                    if not self._validate_workflow_output(actual[key], value):
                        return False
                elif actual[key] != value:
                    return False
            return True
        except (KeyError, TypeError):
            return False

class ServiceTester:
    """System service testing and validation"""
    
    def test_service_status(self, service_name: str) -> TestResult:
        """Test if a system service is running"""
        test_id = f"service_{service_name}"
        start_time = time.time()
        
        try:
            result = subprocess.run(
                ["systemctl", "is-active", service_name],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            duration = time.time() - start_time
            is_active = result.returncode == 0
            
            return TestResult(
                test_id=test_id,
                test_name=f"Service {service_name}",
                test_type="service",
                status="passed" if is_active else "failed",
                duration=duration,
                timestamp=datetime.now(),
                details={
                    "service_name": service_name,
                    "is_active": is_active,
                    "stdout": result.stdout.strip(),
                    "stderr": result.stderr.strip()
                },
                error_message=None if is_active else f"Service {service_name} is not active"
            )
            
        except subprocess.TimeoutExpired:
            return TestResult(
                test_id=test_id,
                test_name=f"Service {service_name}",
                test_type="service",
                status="error",
                duration=time.time() - start_time,
                timestamp=datetime.now(),
                error_message="Service check timeout"
            )
        except Exception as e:
            return TestResult(
                test_id=test_id,
                test_name=f"Service {service_name}",
                test_type="service",
                status="error",
                duration=time.time() - start_time,
                timestamp=datetime.now(),
                error_message=str(e)
            )
    
    async def test_automation_services(self) -> TestSuite:
        """Test all automation-related services"""
        services_to_test = [
            "n8n", "node-red", "postgresql", "redis", 
            "docker", "nginx", "ssh"
        ]
        
        tests = []
        start_time = time.time()
        
        for service in services_to_test:
            result = self.test_service_status(service)
            tests.append(result)
        
        total_duration = time.time() - start_time
        
        # Calculate statistics
        total_tests = len(tests)
        passed_tests = len([t for t in tests if t.status == "passed"])
        failed_tests = len([t for t in tests if t.status == "failed"])
        error_tests = len([t for t in tests if t.status == "error"])
        success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
        
        return TestSuite(
            suite_id="service_suite",
            suite_name="Automation Services Test Suite",
            description="Test status of automation-related system services",
            tests=tests,
            total_tests=total_tests,
            passed_tests=passed_tests,
            failed_tests=failed_tests,
            skipped_tests=0,
            error_tests=error_tests,
            total_duration=total_duration,
            success_rate=success_rate
        )

class IntegrationTestRunner:
    """Main test runner for integration tests"""
    
    def __init__(self):
        self.api_tester = APITester()
        self.workflow_tester = WorkflowTester()
        self.service_tester = ServiceTester()
        self.test_results_db = TEST_RESULTS_DIR / "test_results.db"
        self._init_database()
    
    def _init_database(self):
        """Initialize test results database"""
        with sqlite3.connect(self.test_results_db) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS test_suites (
                    suite_id TEXT PRIMARY KEY,
                    suite_name TEXT,
                    description TEXT,
                    timestamp TIMESTAMP,
                    total_tests INTEGER,
                    passed_tests INTEGER,
                    failed_tests INTEGER,
                    skipped_tests INTEGER,
                    error_tests INTEGER,
                    success_rate REAL,
                    total_duration REAL
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS test_results (
                    test_id TEXT PRIMARY KEY,
                    suite_id TEXT,
                    test_name TEXT,
                    test_type TEXT,
                    status TEXT,
                    duration REAL,
                    timestamp TIMESTAMP,
                    details TEXT,
                    error_message TEXT,
                    FOREIGN KEY (suite_id) REFERENCES test_suites (suite_id)
                )
            """)
    
    def save_test_suite(self, suite: TestSuite):
        """Save test suite results to database"""
        with sqlite3.connect(self.test_results_db) as conn:
            # Save suite
            conn.execute("""
                INSERT OR REPLACE INTO test_suites 
                (suite_id, suite_name, description, timestamp, total_tests, 
                 passed_tests, failed_tests, skipped_tests, error_tests,
                 success_rate, total_duration)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                suite.suite_id, suite.suite_name, suite.description,
                datetime.now(), suite.total_tests, suite.passed_tests,
                suite.failed_tests, suite.skipped_tests, suite.error_tests,
                suite.success_rate, suite.total_duration
            ))
            
            # Save individual test results
            for test in suite.tests:
                conn.execute("""
                    INSERT OR REPLACE INTO test_results
                    (test_id, suite_id, test_name, test_type, status, duration,
                     timestamp, details, error_message)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    test.test_id, suite.suite_id, test.test_name, test.test_type,
                    test.status, test.duration, test.timestamp,
                    json.dumps(test.details) if test.details else None,
                    test.error_message
                ))
    
    async def run_full_integration_tests(self) -> Dict[str, TestSuite]:
        """Run complete integration test suite"""
        logger.info("Starting full integration tests...")
        
        results = {}
        
        # Test automation services
        logger.info("Testing automation services...")
        service_suite = await self.service_tester.test_automation_services()
        results["services"] = service_suite
        self.save_test_suite(service_suite)
        
        # Test API endpoints if services are running
        if service_suite.success_rate > 50:  # If most services are running
            logger.info("Testing API endpoints...")
            api_config = self._get_api_test_config()
            api_suite = await self.api_tester.test_api_suite(api_config)
            results["api"] = api_suite
            self.save_test_suite(api_suite)
        
        # Test workflows if n8n is running
        n8n_test = next((t for t in service_suite.tests if "n8n" in t.test_id), None)
        if n8n_test and n8n_test.status == "passed":
            logger.info("Testing workflow execution...")
            workflow_suite = await self._test_sample_workflows()
            results["workflows"] = workflow_suite
            self.save_test_suite(workflow_suite)
        
        return results
    
    def _get_api_test_config(self) -> Dict:
        """Get API test configuration"""
        return {
            "suite_id": "api_endpoints",
            "name": "API Endpoints Test Suite",
            "description": "Test critical API endpoints for automation services",
            "tests": [
                {
                    "endpoint": "http://localhost:5678/healthz",
                    "method": "GET",
                    "expected_status": 200
                },
                {
                    "endpoint": "http://localhost:1880",
                    "method": "GET",
                    "expected_status": 200
                },
                {
                    "endpoint": "http://localhost:5678/rest/workflows",
                    "method": "GET",
                    "expected_status": 200
                },
                {
                    "endpoint": "http://localhost:1880/flows",
                    "method": "GET",
                    "expected_status": 200
                }
            ]
        }
    
    async def _test_sample_workflows(self) -> TestSuite:
        """Test sample workflows"""
        tests = []
        start_time = time.time()
        
        # Create a simple test workflow if none exist
        sample_workflow_id = await self._ensure_sample_workflow()
        
        if sample_workflow_id:
            # Test workflow execution
            result = await self.workflow_tester.test_workflow_execution(
                workflow_id=sample_workflow_id,
                input_data={"test": "data"},
                timeout=30
            )
            tests.append(result)
        
        total_duration = time.time() - start_time
        
        # Calculate statistics
        total_tests = len(tests)
        passed_tests = len([t for t in tests if t.status == "passed"])
        failed_tests = len([t for t in tests if t.status == "failed"])
        error_tests = len([t for t in tests if t.status == "error"])
        success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
        
        return TestSuite(
            suite_id="workflow_suite",
            suite_name="Workflow Execution Test Suite",
            description="Test workflow execution and validation",
            tests=tests,
            total_tests=total_tests,
            passed_tests=passed_tests,
            failed_tests=failed_tests,
            skipped_tests=0,
            error_tests=error_tests,
            total_duration=total_duration,
            success_rate=success_rate
        )
    
    async def _ensure_sample_workflow(self) -> Optional[str]:
        """Ensure a sample workflow exists for testing"""
        try:
            # Try to get existing workflows
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.workflow_tester.n8n_base_url}/rest/workflows") as response:
                    if response.status == 200:
                        workflows = await response.json()
                        if workflows.get("data"):
                            return workflows["data"][0]["id"]
            
            # If no workflows exist, we could create one here
            # For now, just return None
            return None
            
        except Exception as e:
            logger.error(f"Error checking workflows: {e}")
            return None
    
    def generate_test_report(self, results: Dict[str, TestSuite]) -> str:
        """Generate a comprehensive test report"""
        report = []
        report.append("=" * 60)
        report.append("AUTOMATION INTEGRATION TEST REPORT")
        report.append("=" * 60)
        report.append(f"Generated: {datetime.now().isoformat()}")
        report.append("")
        
        # Overall summary
        total_suites = len(results)
        total_tests = sum(suite.total_tests for suite in results.values())
        total_passed = sum(suite.passed_tests for suite in results.values())
        total_failed = sum(suite.failed_tests for suite in results.values())
        total_errors = sum(suite.error_tests for suite in results.values())
        overall_success_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
        
        report.append("OVERALL SUMMARY")
        report.append("-" * 20)
        report.append(f"Test Suites: {total_suites}")
        report.append(f"Total Tests: {total_tests}")
        report.append(f"Passed: {total_passed}")
        report.append(f"Failed: {total_failed}")
        report.append(f"Errors: {total_errors}")
        report.append(f"Success Rate: {overall_success_rate:.1f}%")
        report.append("")
        
        # Detailed results per suite
        for suite_name, suite in results.items():
            report.append(f"SUITE: {suite.suite_name}")
            report.append("-" * 40)
            report.append(f"Description: {suite.description}")
            report.append(f"Tests: {suite.total_tests}")
            report.append(f"Passed: {suite.passed_tests}")
            report.append(f"Failed: {suite.failed_tests}")
            report.append(f"Errors: {suite.error_tests}")
            report.append(f"Success Rate: {suite.success_rate:.1f}%")
            report.append(f"Duration: {suite.total_duration:.2f}s")
            report.append("")
            
            # Failed tests details
            failed_tests = [t for t in suite.tests if t.status in ["failed", "error"]]
            if failed_tests:
                report.append("FAILED TESTS:")
                for test in failed_tests:
                    report.append(f"  • {test.test_name}: {test.error_message}")
                report.append("")
        
        return "\n".join(report)

async def main():
    """Main CLI interface for the test framework"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Automation Integration Test Framework")
    parser.add_argument("--suite", choices=["all", "services", "api", "workflows"], 
                       default="all", help="Test suite to run")
    parser.add_argument("--output", help="Output file for test results")
    parser.add_argument("--format", choices=["text", "json", "html"], 
                       default="text", help="Output format")
    
    args = parser.parse_args()
    
    runner = IntegrationTestRunner()
    
    try:
        if args.suite == "all":
            results = await runner.run_full_integration_tests()
        elif args.suite == "services":
            service_suite = await runner.service_tester.test_automation_services()
            results = {"services": service_suite}
            runner.save_test_suite(service_suite)
        elif args.suite == "api":
            api_config = runner._get_api_test_config()
            api_suite = await runner.api_tester.test_api_suite(api_config)
            results = {"api": api_suite}
            runner.save_test_suite(api_suite)
        elif args.suite == "workflows":
            workflow_suite = await runner._test_sample_workflows()
            results = {"workflows": workflow_suite}
            runner.save_test_suite(workflow_suite)
        
        # Generate and output report
        if args.format == "text":
            report = runner.generate_test_report(results)
            if args.output:
                with open(args.output, 'w') as f:
                    f.write(report)
                print(f"Test report saved to {args.output}")
            else:
                print(report)
        
        elif args.format == "json":
            report_data = {
                "timestamp": datetime.now().isoformat(),
                "suites": {name: asdict(suite) for name, suite in results.items()}
            }
            output = json.dumps(report_data, indent=2, default=str)
            if args.output:
                with open(args.output, 'w') as f:
                    f.write(output)
                print(f"JSON test results saved to {args.output}")
            else:
                print(output)
        
        # Exit with appropriate code
        total_tests = sum(suite.total_tests for suite in results.values())
        total_failed = sum(suite.failed_tests + suite.error_tests for suite in results.values())
        
        if total_failed > 0:
            logger.error(f"Tests completed with {total_failed} failures/errors")
            sys.exit(1)
        else:
            logger.info(f"All {total_tests} tests passed successfully!")
            sys.exit(0)
            
    except Exception as e:
        logger.error(f"Test execution failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
