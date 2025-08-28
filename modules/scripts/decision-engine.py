#!/usr/bin/env python3
"""
Decision Engine Service
Makes AI-powered decisions for recording control
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
        logging.FileHandler('/var/lib/ai-orchestrator/logs/decision-engine.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger('decision-engine')

class DecisionEngine:
    def __init__(self):
        self.running = False
        self.ai_endpoint = os.getenv('AI_ENDPOINT', 'http://localhost:11434')
        self.decision_frequency = int(os.getenv('DECISION_FREQUENCY', '5'))
        self.confidence_threshold = float(os.getenv('CONFIDENCE_THRESHOLD', '0.7'))
        self.recording_triggers = os.getenv('RECORDING_TRIGGERS', '').split(',')
        self.storage_path = Path('/var/lib/ai-orchestrator')
    
    async def load_analysis_data(self):
        """Load recent analysis data"""
        try:
            analysis_dir = self.storage_path / 'analysis'
            if not analysis_dir.exists():
                return {}
            
            # Get most recent analysis files
            screen_files = sorted(analysis_dir.glob('screen_analysis_*.json'))[-5:]
            audio_files = sorted(analysis_dir.glob('audio_analysis_*.json'))[-5:]
            
            data = {
                'screen_analysis': [],
                'audio_analysis': [],
                'timestamp': datetime.now().isoformat()
            }
            
            # Load screen analysis
            for file_path in screen_files:
                try:
                    with open(file_path) as f:
                        data['screen_analysis'].append(json.load(f))
                except:
                    continue
            
            # Load audio analysis
            for file_path in audio_files:
                try:
                    with open(file_path) as f:
                        data['audio_analysis'].append(json.load(f))
                except:
                    continue
            
            return data
            
        except Exception as e:
            logger.error(f"Error loading analysis data: {e}")
            return {}
    
    async def make_decision(self, analysis_data):
        """Make a recording decision based on analysis data"""
        try:
            decision = {
                'timestamp': datetime.now().isoformat(),
                'action': 'no_change',
                'confidence': 0.5,
                'reasoning': 'Default decision',
                'factors': []
            }
            
            # Analyze screen activity
            screen_activity_score = 0.0
            if analysis_data.get('screen_analysis'):
                recent_screen = analysis_data['screen_analysis'][-1]
                screen_activity_score = recent_screen.get('activity_level', 0.0)
                decision['factors'].append(f"Screen activity: {screen_activity_score:.2f}")
            
            # Analyze audio activity
            audio_activity_score = 0.0
            if analysis_data.get('audio_analysis'):
                recent_audio = analysis_data['audio_analysis'][-1]
                if recent_audio.get('speech_detected'):
                    audio_activity_score = 0.8
                elif recent_audio.get('music_detected'):
                    audio_activity_score = 0.6
                elif recent_audio.get('volume_level', 0) > 0.1:
                    audio_activity_score = 0.4
                decision['factors'].append(f"Audio activity: {audio_activity_score:.2f}")
            
            # Calculate overall confidence
            overall_activity = (screen_activity_score + audio_activity_score) / 2
            decision['confidence'] = overall_activity
            
            # Make decision
            if overall_activity > self.confidence_threshold:
                decision['action'] = 'start_recording'
                decision['reasoning'] = f"High activity detected (score: {overall_activity:.2f})"
            elif overall_activity < 0.2:
                decision['action'] = 'stop_recording'
                decision['reasoning'] = f"Low activity detected (score: {overall_activity:.2f})"
            else:
                decision['reasoning'] = f"Activity within normal range (score: {overall_activity:.2f})"
            
            # Save decision
            decision_file = self.storage_path / 'analysis' / f'decision_{int(time.time())}.json'
            decision_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(decision_file, 'w') as f:
                json.dump(decision, f, indent=2)
            
            return decision
            
        except Exception as e:
            logger.error(f"Error making decision: {e}")
            return {
                'timestamp': datetime.now().isoformat(),
                'action': 'no_change',
                'confidence': 0.0,
                'reasoning': f'Error: {str(e)}',
                'factors': []
            }
    
    async def run(self):
        """Main decision engine loop"""
        logger.info("Decision Engine starting...")
        self.running = True
        
        while self.running:
            try:
                # Load analysis data
                analysis_data = await self.load_analysis_data()
                
                # Make decision
                decision = await self.make_decision(analysis_data)
                
                logger.info(f"Decision: {decision['action']} (confidence: {decision['confidence']:.2f}) - {decision['reasoning']}")
                
                await asyncio.sleep(self.decision_frequency)
                
            except Exception as e:
                logger.error(f"Error in decision loop: {e}")
                await asyncio.sleep(10)

def main():
    engine = DecisionEngine()
    asyncio.run(engine.run())

if __name__ == '__main__':
    main()
