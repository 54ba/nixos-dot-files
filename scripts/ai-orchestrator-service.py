#!/usr/bin/env python3
"""
Enhanced AI Orchestrator Service with proper logging and service management
"""
import os
import sys
import time
import logging
import signal
import subprocess
from pathlib import Path

# Configure logging
LOG_DIR = Path("/var/log/ai-orchestrator")
LOG_DIR.mkdir(exist_ok=True, parents=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / "ai-orchestrator.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger("ai-orchestrator")

class AIOrchestratorService:
    def __init__(self):
        self.running = True
        self.original_script = Path("/etc/nixos/scripts/ai-orchestrator.py")
        
        # Setup signal handlers
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
    def signal_handler(self, signum, frame):
        logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.running = False
        
    def check_dependencies(self):
        """Check if required dependencies are available"""
        try:
            # Check if Ollama is running (if AI integration is enabled)
            if os.getenv("NIXAI_ENABLED", "0") == "1":
                import requests
                endpoint = os.getenv("AI_ENDPOINT", "http://localhost:11434")
                try:
                    response = requests.get(f"{endpoint}/api/tags", timeout=5)
                    if response.status_code == 200:
                        logger.info("AI service (Ollama) is accessible")
                    else:
                        logger.warning(f"AI service returned status {response.status_code}")
                except Exception as e:
                    logger.warning(f"AI service not accessible: {e}")
                    
            return True
        except ImportError as e:
            logger.error(f"Missing dependency: {e}")
            return False
            
    def run_original_script(self):
        """Run the original AI orchestrator script with monitoring"""
        if not self.original_script.exists():
            logger.error(f"Original script not found: {self.original_script}")
            return False
            
        try:
            logger.info("Starting AI Orchestrator main script...")
            
            # Run the original script
            process = subprocess.Popen([
                sys.executable, str(self.original_script)
            ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            
            # Monitor output
            while self.running and process.poll() is None:
                line = process.stdout.readline()
                if line:
                    logger.info(f"AI-Orchestrator: {line.strip()}")
                time.sleep(0.1)
                    
            # Get final output
            remaining_output = process.stdout.read()
            if remaining_output:
                for line in remaining_output.split('\n'):
                    if line.strip():
                        logger.info(f"AI-Orchestrator: {line.strip()}")
                        
            return_code = process.wait()
            logger.info(f"AI Orchestrator script exited with code {return_code}")
            return return_code == 0
            
        except Exception as e:
            logger.error(f"Error running AI orchestrator script: {e}")
            return False
            
    def run(self):
        """Main service loop"""
        logger.info("AI Orchestrator Service starting...")
        
        # Check dependencies
        if not self.check_dependencies():
            logger.error("Dependency check failed")
            return 1
            
        # Create data directories
        data_dir = Path("/var/lib/ai-orchestrator")
        for subdir in ["models", "cache", "logs", "analysis", "feedback"]:
            (data_dir / subdir).mkdir(parents=True, exist_ok=True)
            
        # Log configuration
        logger.info("AI Orchestrator Configuration:")
        logger.info(f"- AI Integration: {os.getenv('NIXAI_ENABLED', '0') == '1'}")
        logger.info(f"- AI Endpoint: {os.getenv('AI_ENDPOINT', 'N/A')}")
        logger.info(f"- Privacy Level: {os.getenv('PRIVACY_LEVEL', 'local_only')}")
        logger.info(f"- Auto Recording: {os.getenv('AUTO_START_RECORDING', '0') == '1'}")
        logger.info(f"- Real-time Analysis: {os.getenv('REALTIME_ANALYSIS', '0') == '1'}")
        
        try:
            # Run the main orchestrator logic
            success = self.run_original_script()
            if success:
                logger.info("AI Orchestrator completed successfully")
                return 0
            else:
                logger.error("AI Orchestrator failed")
                return 1
                
        except KeyboardInterrupt:
            logger.info("Service interrupted by user")
            return 0
        except Exception as e:
            logger.error(f"Service failed with error: {e}")
            return 1
        finally:
            logger.info("AI Orchestrator Service stopped")

if __name__ == "__main__":
    service = AIOrchestratorService()
    sys.exit(service.run())
