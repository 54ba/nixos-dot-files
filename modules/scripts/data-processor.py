#!/usr/bin/env python3
"""
Data Processor Service
Processes collected data in the pipeline
"""

import os
import sys
import json
import time
import logging
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger('data-processor')

class DataProcessor:
    def __init__(self):
        self.pipeline_path = Path(os.getenv('PIPELINE_PATH', '/var/lib/data-pipeline'))
        self.db_backend = os.getenv('DB_BACKEND', 'sqlite')
        self.workers = int(os.getenv('WORKERS', '2'))
        self.algorithms = os.getenv('ALGORITHMS', '').split(',')
        self.partitioning = os.getenv('PARTITIONING', 'daily')
        
        # ML configuration
        self.ml_enabled = os.getenv('ML_ENABLED', '0') == '1'
        self.ml_models = os.getenv('ML_MODELS', '').split(',')
        self.auto_training = os.getenv('AUTO_TRAINING', '0') == '1'
        
    def process_raw_data(self):
        """Process raw data files"""
        try:
            raw_dir = self.pipeline_path / 'raw'
            processed_dir = self.pipeline_path / 'processed'
            processed_dir.mkdir(exist_ok=True)
            
            # Process all raw data files
            for raw_file in raw_dir.glob('*.json'):
                try:
                    with open(raw_file) as f:
                        data = json.load(f)
                    
                    # Simple processing - add processing timestamp
                    data['processed_at'] = time.time()
                    data['processed_by'] = 'data-processor'
                    
                    # Save processed data
                    processed_file = processed_dir / f'processed_{raw_file.name}'
                    with open(processed_file, 'w') as f:
                        json.dump(data, f)
                    
                    # Remove raw file after processing
                    raw_file.unlink()
                    
                    logger.info(f"Processed: {raw_file} -> {processed_file}")
                    
                except Exception as e:
                    logger.error(f"Error processing {raw_file}: {e}")
                    continue
            
            return True
            
        except Exception as e:
            logger.error(f"Error in process_raw_data: {e}")
            return False
    
    def run(self):
        """Main processing loop"""
        logger.info("Data Processor starting...")
        
        try:
            import systemd.daemon
            systemd.daemon.notify('READY=1')
        except ImportError:
            pass
        
        while True:
            try:
                self.process_raw_data()
                time.sleep(5)  # Check for new data every 5 seconds
            except KeyboardInterrupt:
                break
            except Exception as e:
                logger.error(f"Error in processing loop: {e}")
                time.sleep(10)
        
        logger.info("Data Processor stopping...")

def main():
    processor = DataProcessor()
    processor.run()

if __name__ == '__main__':
    main()
