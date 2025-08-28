#!/usr/bin/env python3
"""
Data Collector Service
Collects data from various sources for the pipeline
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

logger = logging.getLogger('data-collector')

class DataCollector:
    def __init__(self):
        self.pipeline_path = Path(os.getenv('PIPELINE_PATH', '/var/lib/data-pipeline'))
        self.collection_interval = int(os.getenv('COLLECTION_INTERVAL', '10'))
        self.batch_size = int(os.getenv('BATCH_SIZE', '100'))
        self.compression = os.getenv('COMPRESSION', '0') == '1'
        self.sources = os.getenv('SOURCES', '').split(',')
        
        # Ensure data directories exist
        (self.pipeline_path / 'raw').mkdir(parents=True, exist_ok=True)
        (self.pipeline_path / 'processed').mkdir(parents=True, exist_ok=True)
        
    def collect_data(self):
        """Collect data from configured sources"""
        try:
            data = {
                'timestamp': time.time(),
                'sources': self.sources,
                'batch_size': self.batch_size,
                'status': 'collected'
            }
            
            # Save to raw data directory
            raw_file = self.pipeline_path / 'raw' / f'data_{int(time.time())}.json'
            with open(raw_file, 'w') as f:
                json.dump(data, f)
            
            logger.info(f"Collected data batch: {raw_file}")
            return True
            
        except Exception as e:
            logger.error(f"Error collecting data: {e}")
            return False
    
    def run(self):
        """Main collection loop"""
        logger.info("Data Collector starting...")
        
        try:
            import systemd.daemon
            systemd.daemon.notify('READY=1')
        except ImportError:
            pass
        
        while True:
            try:
                self.collect_data()
                time.sleep(self.collection_interval)
            except KeyboardInterrupt:
                break
            except Exception as e:
                logger.error(f"Error in collection loop: {e}")
                time.sleep(5)
        
        logger.info("Data Collector stopping...")

def main():
    collector = DataCollector()
    collector.run()

if __name__ == '__main__':
    main()
