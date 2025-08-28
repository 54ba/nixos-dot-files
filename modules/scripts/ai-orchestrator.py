#!/usr/bin/env python3
"""
AI Orchestrator Service
Coordinates intelligent recording control based on AI analysis
"""

import os
import sys
import json
import time
import logging
import asyncio
import signal
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/lib/ai-orchestrator/logs/orchestrator.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger('ai-orchestrator')

@dataclass
class OrchestratorConfig:
    """Configuration for AI orchestrator"""
    nixai_enabled: bool = True
    ai_model: str = "local"
    ai_endpoint: str = "http://localhost:11434"
    ai_models: List[str] = None
    context_window: int = 300
    decision_frequency: int = 5
    confidence_threshold: float = 0.7
    adaptive_threshold: bool = True
    learning_enabled: bool = True
    auto_start_recording: bool = True
    auto_stop_recording: bool = True
    smart_segmentation: bool = True
    recording_triggers: List[str] = None
    quality_adaptation: bool = True
    realtime_analysis: bool = True
    screen_analysis: bool = True
    audio_analysis: bool = True
    activity_classification: bool = True
    auto_apply_effects: bool = True
    effect_types: List[str] = None
    effect_intensity: str = "moderate"
    auto_optimize_stream: bool = True
    privacy_level: str = "local_only"
    excluded_apps: List[str] = None
    sensitive_detection: bool = True
    notifications_enabled: bool = True
    notification_verbosity: str = "normal"
    notification_channels: List[str] = None
    
    def __post_init__(self):
        if self.ai_models is None:
            self.ai_models = ["llama3.1", "codellama", "vision"]
        if self.recording_triggers is None:
            self.recording_triggers = [
                "presentation_mode", "coding_session", "meeting_detected",
                "tutorial_creation", "error_troubleshooting"
            ]
        if self.effect_types is None:
            self.effect_types = [
                "zoom_enhancement", "highlight_cursor", "smooth_transitions",
                "auto_crop", "noise_reduction", "brightness_adjustment"
            ]
        if self.excluded_apps is None:
            self.excluded_apps = ["keepassxc", "bitwarden", "banking", "private"]
        if self.notification_channels is None:
            self.notification_channels = ["desktop", "system"]

@dataclass
class SystemState:
    """Current system state for AI decision making"""
    current_app: str = ""
    screen_activity: str = "idle"
    audio_activity: str = "silent"
    recording_active: bool = False
    streaming_active: bool = False
    cpu_usage: float = 0.0
    memory_usage: float = 0.0
    confidence_score: float = 0.0
    last_decision: str = ""
    decision_timestamp: datetime = None

class AIOrchestrator:
    """Main AI orchestrator service"""
    
    def __init__(self):
        self.config = self.load_config()
        self.state = SystemState()
        self.running = False
        self.storage_path = Path('/var/lib/ai-orchestrator')
        self.analysis_cache = {}
        self.decision_history = []
        
        # Setup storage directories
        self.ensure_directories()
        
        # Setup signal handlers
        signal.signal(signal.SIGTERM, self.handle_shutdown)
        signal.signal(signal.SIGINT, self.handle_shutdown)
        
    def load_config(self) -> OrchestratorConfig:
        """Load configuration from environment variables"""
        return OrchestratorConfig(
            nixai_enabled=os.getenv('NIXAI_ENABLED', '1') == '1',
            ai_model=os.getenv('AI_MODEL', 'local'),
            ai_endpoint=os.getenv('AI_ENDPOINT', 'http://localhost:11434'),
            ai_models=os.getenv('AI_MODELS', 'llama3.1,codellama,vision').split(','),
            context_window=int(os.getenv('CONTEXT_WINDOW', '300')),
            decision_frequency=int(os.getenv('DECISION_FREQUENCY', '5')),
            confidence_threshold=float(os.getenv('CONFIDENCE_THRESHOLD', '0.7')),
            adaptive_threshold=os.getenv('ADAPTIVE_THRESHOLD', '1') == '1',
            learning_enabled=os.getenv('LEARNING_ENABLED', '1') == '1',
            auto_start_recording=os.getenv('AUTO_START_RECORDING', '1') == '1',
            auto_stop_recording=os.getenv('AUTO_STOP_RECORDING', '1') == '1',
            smart_segmentation=os.getenv('SMART_SEGMENTATION', '1') == '1',
            recording_triggers=os.getenv('RECORDING_TRIGGERS', 
                'presentation_mode,coding_session,meeting_detected,tutorial_creation,error_troubleshooting').split(','),
            quality_adaptation=os.getenv('QUALITY_ADAPTATION', '1') == '1',
            realtime_analysis=os.getenv('REALTIME_ANALYSIS', '1') == '1',
            screen_analysis=os.getenv('SCREEN_ANALYSIS', '1') == '1',
            audio_analysis=os.getenv('AUDIO_ANALYSIS', '1') == '1',
            activity_classification=os.getenv('ACTIVITY_CLASSIFICATION', '1') == '1',
            auto_apply_effects=os.getenv('AUTO_APPLY_EFFECTS', '1') == '1',
            effect_types=os.getenv('EFFECT_TYPES', 
                'zoom_enhancement,highlight_cursor,smooth_transitions,auto_crop,noise_reduction,brightness_adjustment').split(','),
            effect_intensity=os.getenv('EFFECT_INTENSITY', 'moderate'),
            auto_optimize_stream=os.getenv('AUTO_OPTIMIZE_STREAM', '1') == '1',
            privacy_level=os.getenv('PRIVACY_LEVEL', 'local_only'),
            excluded_apps=os.getenv('EXCLUDED_APPS', 'keepassxc,bitwarden,banking,private').split(','),
            sensitive_detection=os.getenv('SENSITIVE_DETECTION', '1') == '1',
            notifications_enabled=os.getenv('NOTIFICATIONS_ENABLED', '1') == '1',
            notification_verbosity=os.getenv('NOTIFICATION_VERBOSITY', 'normal'),
            notification_channels=os.getenv('NOTIFICATION_CHANNELS', 'desktop,system').split(',')
        )
    
    def ensure_directories(self):
        """Ensure all required directories exist"""
        directories = [
            'logs', 'models', 'cache', 'analysis', 'feedback', 'state'
        ]
        for dir_name in directories:
            dir_path = self.storage_path / dir_name
            dir_path.mkdir(parents=True, exist_ok=True)
    
    def handle_shutdown(self, signum, frame):
        """Handle shutdown signals gracefully"""
        logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.running = False
    
    async def get_system_state(self) -> SystemState:
        """Get current system state for decision making"""
        try:
            # Get active window/application
            current_app = await self.get_active_application()
            
            # Get system resource usage
            cpu_usage, memory_usage = await self.get_resource_usage()
            
            # Update state
            self.state.current_app = current_app
            self.state.cpu_usage = cpu_usage
            self.state.memory_usage = memory_usage
            
            # Check if we're in excluded apps
            if any(excluded in current_app.lower() for excluded in self.config.excluded_apps):
                self.state.screen_activity = "excluded"
            
            return self.state
            
        except Exception as e:
            logger.error(f"Error getting system state: {e}")
            return self.state
    
    async def get_active_application(self) -> str:
        """Get the currently active application"""
        try:
            # Try to get active window via various methods
            import subprocess
            
            # Try xdotool first (X11)
            try:
                result = subprocess.run([
                    'xdotool', 'getwindowfocus', 'getwindowname'
                ], capture_output=True, text=True, timeout=2)
                if result.returncode == 0:
                    return result.stdout.strip()
            except:
                pass
            
            # Try wmctrl as fallback
            try:
                result = subprocess.run([
                    'wmctrl', '-l'
                ], capture_output=True, text=True, timeout=2)
                if result.returncode == 0:
                    lines = result.stdout.strip().split('\n')
                    for line in lines:
                        if '*' in line:  # Active window marker
                            parts = line.split()
                            return ' '.join(parts[3:]) if len(parts) > 3 else "unknown"
            except:
                pass
                
            return "unknown"
            
        except Exception as e:
            logger.error(f"Error getting active application: {e}")
            return "unknown"
    
    async def get_resource_usage(self) -> Tuple[float, float]:
        """Get CPU and memory usage"""
        try:
            import psutil
            cpu_usage = psutil.cpu_percent(interval=0.1)
            memory_info = psutil.virtual_memory()
            memory_usage = memory_info.percent
            return cpu_usage, memory_usage
        except ImportError:
            # Fallback to reading /proc files
            try:
                # Simple CPU usage estimation
                with open('/proc/loadavg', 'r') as f:
                    load_avg = float(f.read().split()[0])
                cpu_usage = min(load_avg * 100, 100.0)
                
                # Memory usage
                with open('/proc/meminfo', 'r') as f:
                    lines = f.readlines()
                    mem_total = int([l for l in lines if l.startswith('MemTotal')][0].split()[1])
                    mem_available = int([l for l in lines if l.startswith('MemAvailable')][0].split()[1])
                    memory_usage = ((mem_total - mem_available) / mem_total) * 100
                
                return cpu_usage, memory_usage
            except:
                return 0.0, 0.0
    
    async def make_recording_decision(self) -> Dict[str, any]:
        """Make AI-powered decision about recording control"""
        try:
            state = await self.get_system_state()
            
            # Simple rule-based logic for now (can be enhanced with actual AI)
            decision = {
                'action': 'no_change',
                'confidence': 0.5,
                'reasoning': 'Default state',
                'timestamp': datetime.now().isoformat()
            }
            
            # Check for high CPU/memory usage (might indicate interesting activity)
            if state.cpu_usage > 50 or state.memory_usage > 70:
                decision['action'] = 'start_recording' if not state.recording_active else 'continue_recording'
                decision['confidence'] = min(0.8, (state.cpu_usage + state.memory_usage) / 100)
                decision['reasoning'] = f'High system activity detected (CPU: {state.cpu_usage}%, RAM: {state.memory_usage}%)'
            
            # Check for specific applications that might warrant recording
            interesting_apps = ['code', 'terminal', 'browser', 'presentation', 'zoom', 'meet']
            if any(app in state.current_app.lower() for app in interesting_apps):
                decision['action'] = 'start_recording' if not state.recording_active else 'continue_recording'
                decision['confidence'] = max(decision['confidence'], 0.7)
                decision['reasoning'] = f'Interesting application detected: {state.current_app}'
            
            # Check if we're in an excluded app
            if state.screen_activity == "excluded":
                decision['action'] = 'pause_recording' if state.recording_active else 'no_change'
                decision['confidence'] = 0.9
                decision['reasoning'] = f'Privacy-sensitive application detected: {state.current_app}'
            
            # Apply confidence threshold
            if decision['confidence'] < self.config.confidence_threshold:
                decision['action'] = 'no_change'
                decision['reasoning'] += f' (Below confidence threshold: {decision["confidence"]:.2f} < {self.config.confidence_threshold})'
            
            # Store decision in history
            self.decision_history.append(decision)
            if len(self.decision_history) > 100:  # Keep last 100 decisions
                self.decision_history.pop(0)
            
            # Update state
            self.state.confidence_score = decision['confidence']
            self.state.last_decision = decision['action']
            self.state.decision_timestamp = datetime.now()
            
            return decision
            
        except Exception as e:
            logger.error(f"Error making recording decision: {e}")
            return {
                'action': 'no_change',
                'confidence': 0.0,
                'reasoning': f'Error in decision making: {str(e)}',
                'timestamp': datetime.now().isoformat()
            }
    
    async def execute_decision(self, decision: Dict[str, any]):
        """Execute the AI decision"""
        try:
            action = decision['action']
            logger.info(f"Executing decision: {action} (confidence: {decision['confidence']:.2f})")
            
            if action == 'start_recording':
                await self.start_recording()
            elif action == 'stop_recording':
                await self.stop_recording()
            elif action == 'pause_recording':
                await self.pause_recording()
            elif action == 'continue_recording':
                # Recording already active, no action needed
                pass
            elif action == 'no_change':
                # No action needed
                pass
            
            # Send notification if enabled
            if self.config.notifications_enabled:
                await self.send_notification(decision)
                
        except Exception as e:
            logger.error(f"Error executing decision: {e}")
    
    async def start_recording(self):
        """Start recording"""
        try:
            import subprocess
            
            # Try to communicate with the desktop recording service
            result = subprocess.run([
                'systemctl', '--user', 'start', 'desktop-recorder'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                self.state.recording_active = True
                logger.info("Recording started successfully")
            else:
                logger.error(f"Failed to start recording: {result.stderr}")
                
        except Exception as e:
            logger.error(f"Error starting recording: {e}")
    
    async def stop_recording(self):
        """Stop recording"""
        try:
            import subprocess
            
            result = subprocess.run([
                'systemctl', '--user', 'stop', 'desktop-recorder'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                self.state.recording_active = False
                logger.info("Recording stopped successfully")
            else:
                logger.error(f"Failed to stop recording: {result.stderr}")
                
        except Exception as e:
            logger.error(f"Error stopping recording: {e}")
    
    async def pause_recording(self):
        """Pause recording (stop for now, can be enhanced)"""
        await self.stop_recording()
    
    async def send_notification(self, decision: Dict[str, any]):
        """Send notification about AI decision"""
        try:
            if 'desktop' in self.config.notification_channels:
                import subprocess
                
                title = "AI Orchestrator"
                message = f"Action: {decision['action']}\nConfidence: {decision['confidence']:.2f}\nReason: {decision['reasoning']}"
                
                # Try to send desktop notification
                subprocess.run([
                    'notify-send', title, message
                ], timeout=5)
                
        except Exception as e:
            logger.error(f"Error sending notification: {e}")
    
    async def save_state(self):
        """Save current state to disk"""
        try:
            state_file = self.storage_path / 'state' / 'orchestrator_state.json'
            state_data = {
                'state': asdict(self.state),
                'config': asdict(self.config),
                'decision_history': self.decision_history[-10:],  # Last 10 decisions
                'timestamp': datetime.now().isoformat()
            }
            
            with open(state_file, 'w') as f:
                json.dump(state_data, f, indent=2, default=str)
                
        except Exception as e:
            logger.error(f"Error saving state: {e}")
    
    async def run(self):
        """Main orchestrator loop"""
        logger.info("AI Orchestrator starting...")
        self.running = True
        
        try:
            while self.running:
                try:
                    # Make AI decision
                    decision = await self.make_recording_decision()
                    
                    # Execute decision
                    await self.execute_decision(decision)
                    
                    # Save state periodically
                    await self.save_state()
                    
                    # Wait for next decision cycle
                    await asyncio.sleep(self.config.decision_frequency)
                    
                except Exception as e:
                    logger.error(f"Error in main loop: {e}")
                    await asyncio.sleep(5)  # Wait a bit before retrying
                    
        except KeyboardInterrupt:
            pass
        finally:
            logger.info("AI Orchestrator shutting down...")
            await self.save_state()

def main():
    """Main entry point"""
    try:
        # Notify systemd that we're ready
        import systemd.daemon
        systemd.daemon.notify('READY=1')
    except ImportError:
        pass  # systemd not available, continue anyway
    
    orchestrator = AIOrchestrator()
    
    # Run the orchestrator
    asyncio.run(orchestrator.run())

if __name__ == '__main__':
    main()
