#!/usr/bin/env python3
"""
Screen Analyzer Service
Analyzes screen content for AI orchestrator
"""

import os
import sys
import time
import logging
import asyncio
import json
from pathlib import Path
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/lib/ai-orchestrator/logs/screen-analyzer.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger('screen-analyzer')

class ScreenAnalyzer:
    def __init__(self):
        self.running = False
        self.ai_endpoint = os.getenv('AI_ENDPOINT', 'http://localhost:11434')
        self.analysis_frequency = int(os.getenv('ANALYSIS_FREQUENCY', '2'))
        self.privacy_level = os.getenv('PRIVACY_LEVEL', 'local_only')
        self.excluded_apps = os.getenv('EXCLUDED_APPS', '').split(',')
        self.storage_path = Path('/var/lib/ai-orchestrator')
    
    async def capture_screenshot(self):
        """Capture current screen content"""
        try:
            import subprocess
            timestamp = int(time.time())
            screenshot_path = f"/tmp/screen_capture_{timestamp}.png"
            
            # Try different screenshot methods
            for cmd in [
                ['gnome-screenshot', '-f', screenshot_path],
                ['import', '-window', 'root', screenshot_path],
                ['scrot', screenshot_path]
            ]:
                try:
                    result = subprocess.run(cmd, capture_output=True, timeout=5)
                    if result.returncode == 0 and Path(screenshot_path).exists():
                        return screenshot_path
                except:
                    continue
            
            return None
        except Exception as e:
            logger.error(f"Error capturing screenshot: {e}")
            return None
    
    async def analyze_screen_content(self, screenshot_path):
        """Analyze screenshot content"""
        try:
            # Simple analysis for now - can be enhanced with actual AI/ML
            analysis = {
                'timestamp': datetime.now().isoformat(),
                'screenshot': screenshot_path,
                'content_type': 'unknown',
                'activity_level': 0.5,
                'text_detected': False,
                'ui_elements': [],
                'privacy_sensitive': False
            }
            
            # Save analysis result
            analysis_file = self.storage_path / 'analysis' / f'screen_analysis_{int(time.time())}.json'
            analysis_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(analysis_file, 'w') as f:
                json.dump(analysis, f, indent=2)
            
            return analysis
            
        except Exception as e:
            logger.error(f"Error analyzing screen content: {e}")
            return None
    
    async def run(self):
        """Main analyzer loop"""
        logger.info("Screen Analyzer starting...")
        self.running = True
        
        while self.running:
            try:
                # Capture screenshot
                screenshot_path = await self.capture_screenshot()
                
                if screenshot_path:
                    # Analyze content
                    analysis = await self.analyze_screen_content(screenshot_path)
                    
                    if analysis:
                        logger.info(f"Screen analysis completed: {analysis['content_type']}")
                    
                    # Clean up screenshot
                    try:
                        os.unlink(screenshot_path)
                    except:
                        pass
                
                await asyncio.sleep(self.analysis_frequency)
                
            except Exception as e:
                logger.error(f"Error in analyzer loop: {e}")
                await asyncio.sleep(5)

def main():
    analyzer = ScreenAnalyzer()
    asyncio.run(analyzer.run())

if __name__ == '__main__':
    main()
