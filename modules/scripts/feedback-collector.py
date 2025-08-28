#!/usr/bin/env python3
"""
Feedback Collector Service
Collects user feedback for AI learning
"""

import os
import sys
import json
import time
import logging
import asyncio
from pathlib import Path
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/lib/ai-orchestrator/logs/feedback-collector.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger('feedback-collector')

class FeedbackCollector:
    def __init__(self):
        self.running = False
        self.feedback_path = Path(os.getenv('FEEDBACK_PATH', '/var/lib/ai-orchestrator/feedback'))
        self.learning_enabled = os.getenv('LEARNING_ENABLED', '1') == '1'
        self.feedback_path.mkdir(parents=True, exist_ok=True)
    
    async def collect_implicit_feedback(self):
        """Collect implicit feedback from user behavior"""
        try:
            # Simple implicit feedback collection
            feedback = {
                'timestamp': datetime.now().isoformat(),
                'type': 'implicit',
                'source': 'system',
                'data': {
                    'user_active': True,
                    'system_responsive': True,
                    'recording_interruptions': 0
                }
            }
            
            # Save feedback
            feedback_file = self.feedback_path / f'implicit_feedback_{int(time.time())}.json'
            
            with open(feedback_file, 'w') as f:
                json.dump(feedback, f, indent=2)
            
            return feedback
            
        except Exception as e:
            logger.error(f"Error collecting implicit feedback: {e}")
            return None
    
    async def process_feedback_queue(self):
        """Process queued feedback items"""
        try:
            # Look for feedback files to process
            feedback_files = list(self.feedback_path.glob('*.json'))
            
            for feedback_file in feedback_files:
                try:
                    with open(feedback_file) as f:
                        feedback_data = json.load(f)
                    
                    # Process feedback (simplified)
                    logger.info(f"Processing feedback: {feedback_data.get('type', 'unknown')}")
                    
                    # Move to processed folder
                    processed_dir = self.feedback_path / 'processed'
                    processed_dir.mkdir(exist_ok=True)
                    
                    processed_file = processed_dir / feedback_file.name
                    feedback_file.rename(processed_file)
                    
                except Exception as e:
                    logger.error(f"Error processing feedback file {feedback_file}: {e}")
                    continue
            
        except Exception as e:
            logger.error(f"Error processing feedback queue: {e}")
    
    async def run(self):
        """Main feedback collector loop"""
        if not self.learning_enabled:
            logger.info("Learning disabled, feedback collector not running")
            return
        
        logger.info("Feedback Collector starting...")
        self.running = True
        
        while self.running:
            try:
                # Collect implicit feedback
                await self.collect_implicit_feedback()
                
                # Process feedback queue
                await self.process_feedback_queue()
                
                await asyncio.sleep(30)  # Collect feedback every 30 seconds
                
            except Exception as e:
                logger.error(f"Error in feedback collector loop: {e}")
                await asyncio.sleep(60)

def main():
    collector = FeedbackCollector()
    asyncio.run(collector.run())

if __name__ == '__main__':
    main()
