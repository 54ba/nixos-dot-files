#!/usr/bin/env python3
"""
Desktop Recording Daemon
A D-Bus service for managing desktop recordings in NixOS.
"""

import os
import sys
import time
import subprocess
import signal
import logging
from pathlib import Path
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib


class RecordingDaemon(dbus.service.Object):
    """D-Bus service for desktop recording management."""
    
    def __init__(self):
        # Initialize D-Bus
        DBusGMainLoop(set_as_default=True)
        bus = dbus.SystemBus()
        bus_name = dbus.service.BusName('org.nixos.DesktopRecorder', bus)
        super().__init__(bus_name, '/org/nixos/DesktopRecorder')
        
        # Configuration from environment
        self.recording_path = Path(os.getenv('RECORDING_PATH', '/var/lib/desktop-recordings'))
        self.quality = os.getenv('RECORDING_QUALITY', 'medium')
        self.fps = int(os.getenv('RECORDING_FPS', '30'))
        self.format = os.getenv('RECORDING_FORMAT', 'mp4')
        self.codec = os.getenv('RECORDING_CODEC', 'h264')
        
        # State management
        self.is_recording = False
        self.recording_process = None
        self.current_session = None
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.recording_path / 'daemon.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger('RecordingDaemon')
        
        # Ensure recording directories exist
        self.recording_path.mkdir(parents=True, exist_ok=True)
        (self.recording_path / 'sessions').mkdir(exist_ok=True)
        (self.recording_path / 'clips').mkdir(exist_ok=True)
        (self.recording_path / 'streams').mkdir(exist_ok=True)
        
        self.logger.info("Desktop Recording Daemon initialized")
        
    @dbus.service.method('org.nixos.DesktopRecorder', in_signature='s', out_signature='b')
    def StartRecording(self, session_name=''):
        """Start a new recording session."""
        if self.is_recording:
            self.logger.warning("Recording already in progress")
            return False
            
        try:
            # Generate session name if not provided
            if not session_name:
                session_name = f"session_{int(time.time())}"
            
            self.current_session = session_name
            output_file = self.recording_path / 'sessions' / f"{session_name}.{self.format}"
            
            # Build recording command based on available tools
            if self._check_command('wf-recorder'):
                # Use wf-recorder for Wayland
                cmd = [
                    'wf-recorder',
                    '-f', str(output_file),
                    '-r', str(self.fps),
                    '--audio'
                ]
            elif self._check_command('ffmpeg'):
                # Fallback to ffmpeg
                cmd = [
                    'ffmpeg',
                    '-f', 'x11grab',
                    '-r', str(self.fps),
                    '-i', ':0.0',
                    '-f', 'pulse',
                    '-i', 'default',
                    '-c:v', self.codec,
                    '-crf', '18',
                    str(output_file)
                ]
            else:
                self.logger.error("No suitable recording tool found")
                return False
            
            # Start recording process
            self.recording_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                preexec_fn=os.setsid
            )
            
            self.is_recording = True
            self.logger.info(f"Started recording session: {session_name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to start recording: {e}")
            return False
    
    @dbus.service.method('org.nixos.DesktopRecorder', out_signature='b')
    def StopRecording(self):
        """Stop the current recording session."""
        if not self.is_recording or not self.recording_process:
            self.logger.warning("No recording in progress")
            return False
            
        try:
            # Gracefully terminate recording process
            os.killpg(os.getpgid(self.recording_process.pid), signal.SIGTERM)
            
            # Wait for process to finish
            try:
                self.recording_process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                # Force kill if graceful termination fails
                os.killpg(os.getpgid(self.recording_process.pid), signal.SIGKILL)
                self.recording_process.wait()
            
            self.is_recording = False
            self.logger.info(f"Stopped recording session: {self.current_session}")
            self.current_session = None
            self.recording_process = None
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to stop recording: {e}")
            return False
    
    @dbus.service.method('org.nixos.DesktopRecorder', out_signature='b')
    def IsRecording(self):
        """Check if currently recording."""
        return self.is_recording
    
    @dbus.service.method('org.nixos.DesktopRecorder', out_signature='s')
    def GetCurrentSession(self):
        """Get the name of the current recording session."""
        return self.current_session or ""
    
    @dbus.service.method('org.nixos.DesktopRecorder', out_signature='as')
    def ListSessions(self):
        """List all available recording sessions."""
        try:
            sessions_dir = self.recording_path / 'sessions'
            if not sessions_dir.exists():
                return []
            
            sessions = [
                f.stem for f in sessions_dir.iterdir() 
                if f.is_file() and f.suffix[1:] == self.format
            ]
            return sorted(sessions)
            
        except Exception as e:
            self.logger.error(f"Failed to list sessions: {e}")
            return []
    
    @dbus.service.method('org.nixos.DesktopRecorder', in_signature='s', out_signature='b')
    def DeleteSession(self, session_name):
        """Delete a recording session."""
        try:
            session_file = self.recording_path / 'sessions' / f"{session_name}.{self.format}"
            if session_file.exists():
                session_file.unlink()
                self.logger.info(f"Deleted session: {session_name}")
                return True
            else:
                self.logger.warning(f"Session not found: {session_name}")
                return False
                
        except Exception as e:
            self.logger.error(f"Failed to delete session {session_name}: {e}")
            return False
    
    def _check_command(self, command):
        """Check if a command is available in PATH."""
        try:
            subprocess.run(['which', command], check=True, capture_output=True)
            return True
        except subprocess.CalledProcessError:
            return False
    
    def cleanup(self):
        """Clean up resources on shutdown."""
        if self.is_recording:
            self.StopRecording()
        self.logger.info("Desktop Recording Daemon shutting down")


def signal_handler(signum, frame):
    """Handle shutdown signals."""
    daemon.cleanup()
    sys.exit(0)


if __name__ == '__main__':
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Create and run daemon
        daemon = RecordingDaemon()
        
        # Run main loop
        loop = GLib.MainLoop()
        daemon.logger.info("Desktop Recording Daemon started")
        loop.run()
        
    except KeyboardInterrupt:
        daemon.cleanup()
    except Exception as e:
        logging.error(f"Daemon failed: {e}")
        sys.exit(1)
