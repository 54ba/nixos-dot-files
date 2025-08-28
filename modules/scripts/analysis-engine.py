#!/usr/bin/env python3
"""
Analysis Engine Service
Performs analysis on processed data
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

logger = logging.getLogger('analysis-engine')

class AnalysisEngine:
    def __init__(self):
        self.pipeline_path = Path(os.getenv('PIPELINE_PATH', '/var/lib/data-pipeline'))
        self.metrics = os.getenv('METRICS', '').split(',')
        self.db_backend = os.getenv('DB_BACKEND', 'sqlite')
        
    def analyze_data(self):
        """Analyze processed data"""
        try:
            processed_dir = self.pipeline_path / 'processed'
            analysis_dir = self.pipeline_path / 'analysis'
            analysis_dir.mkdir(exist_ok=True)
            
            # Analyze all processed data files
            for processed_file in processed_dir.glob('processed_*.json'):
                try:
                    with open(processed_file) as f:
                        data = json.load(f)
                    
                    # Simple analysis
                    analysis = {
                        'analyzed_at': time.time(),
                        'source_file': processed_file.name,
                        'metrics': {
                            'data_points': len(data.get('sources', [])),
                            'processing_time': data.get('processed_at', 0) - data.get('timestamp', 0),
                            'status': 'analyzed'
                        }
                    }
                    
                    # Save analysis results
                    analysis_file = analysis_dir / f'analysis_{processed_file.stem}.json'
                    with open(analysis_file, 'w') as f:
                        json.dump(analysis, f)
                    
                    logger.info(f"Analyzed: {processed_file} -> {analysis_file}")
                    
                except Exception as e:
                    logger.error(f"Error analyzing {processed_file}: {e}")
                    continue
            
            return True
            
        except Exception as e:
            logger.error(f"Error in analyze_data: {e}")
            return False
    
    def run(self):
        """Main analysis loop"""
        logger.info("Analysis Engine starting...")
        
        while True:
            try:
                self.analyze_data()
                time.sleep(10)  # Run analysis every 10 seconds
            except KeyboardInterrupt:
                break
            except Exception as e:
                logger.error(f"Error in analysis loop: {e}")
                time.sleep(15)
        
        logger.info("Analysis Engine stopping...")

def main():
    engine = AnalysisEngine()
    engine.run()

if __name__ == '__main__':
    main()
