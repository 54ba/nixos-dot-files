#!/usr/bin/env python3
"""
Enhanced Data Pipeline Service with proper logging and service management
"""
import os
import sys
import time
import logging
import signal
import subprocess
from pathlib import Path

# Configure logging
LOG_DIR = Path("/var/log/data-pipeline")
LOG_DIR.mkdir(exist_ok=True, parents=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / "data-pipeline.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger("data-pipeline")

class DataPipelineService:
    def __init__(self):
        self.running = True
        self.original_script = Path("/etc/nixos/scripts/pipeline-api.py")
        
        # Setup signal handlers
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
    def signal_handler(self, signum, frame):
        logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.running = False
        
    def check_dependencies(self):
        """Check if required dependencies are available"""
        try:
            # Check database connectivity
            backend = os.getenv("DB_BACKEND", "sqlite")
            
            if backend == "postgresql":
                import psycopg2
                logger.info("PostgreSQL connector available")
            elif backend == "sqlite":
                import sqlite3
                logger.info("SQLite connector available")
            
            # Check data directories
            pipeline_path = Path(os.getenv("PIPELINE_PATH", "/var/lib/data-pipeline"))
            if not pipeline_path.exists():
                logger.warning(f"Pipeline path does not exist: {pipeline_path}")
                pipeline_path.mkdir(parents=True, exist_ok=True)
                logger.info(f"Created pipeline path: {pipeline_path}")
                
            return True
        except ImportError as e:
            logger.error(f"Missing dependency: {e}")
            return False
            
    def setup_directories(self):
        """Setup required directories"""
        pipeline_path = Path(os.getenv("PIPELINE_PATH", "/var/lib/data-pipeline"))
        
        subdirs = ["raw", "processed", "models", "cache", "exports", "queue"]
        for subdir in subdirs:
            (pipeline_path / subdir).mkdir(parents=True, exist_ok=True)
            
        logger.info(f"Data pipeline directories ready at {pipeline_path}")
        
    def run_original_script(self):
        """Run the original pipeline API script with monitoring"""
        if not self.original_script.exists():
            logger.error(f"Original script not found: {self.original_script}")
            return False
            
        try:
            logger.info("Starting Data Pipeline API server...")
            
            # Run the original script
            process = subprocess.Popen([
                sys.executable, str(self.original_script)
            ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            
            # Monitor output
            while self.running and process.poll() is None:
                line = process.stdout.readline()
                if line:
                    logger.info(f"Pipeline-API: {line.strip()}")
                time.sleep(0.1)
                    
            # Get final output
            remaining_output = process.stdout.read()
            if remaining_output:
                for line in remaining_output.split('\n'):
                    if line.strip():
                        logger.info(f"Pipeline-API: {line.strip()}")
                        
            return_code = process.wait()
            logger.info(f"Data Pipeline API exited with code {return_code}")
            return return_code == 0
            
        except Exception as e:
            logger.error(f"Error running pipeline API: {e}")
            return False
            
    def run(self):
        """Main service loop"""
        logger.info("Data Pipeline Service starting...")
        
        # Check dependencies
        if not self.check_dependencies():
            logger.error("Dependency check failed")
            return 1
            
        # Setup directories
        self.setup_directories()
            
        # Log configuration
        logger.info("Data Pipeline Configuration:")
        logger.info(f"- Storage Path: {os.getenv('PIPELINE_PATH', 'N/A')}")
        logger.info(f"- API Port: {os.getenv('API_PORT', 'N/A')}")
        logger.info(f"- Database Backend: {os.getenv('DB_BACKEND', 'N/A')}")
        logger.info(f"- Authentication: {os.getenv('AUTH_ENABLED', '0') == '1'}")
        logger.info(f"- Streaming: {os.getenv('STREAMING_ENABLED', '0') == '1'}")
        
        try:
            # Run the main pipeline API
            success = self.run_original_script()
            if success:
                logger.info("Data Pipeline completed successfully")
                return 0
            else:
                logger.error("Data Pipeline failed")
                return 1
                
        except KeyboardInterrupt:
            logger.info("Service interrupted by user")
            return 0
        except Exception as e:
            logger.error(f"Service failed with error: {e}")
            return 1
        finally:
            logger.info("Data Pipeline Service stopped")

if __name__ == "__main__":
    service = DataPipelineService()
    sys.exit(service.run())
