#!/usr/bin/env python3

import os
import sys
import time
import json
import sqlite3
import psutil
import logging
from pathlib import Path
from datetime import datetime, timedelta

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('pipeline-monitor')

class PipelineMonitor:
    def __init__(self):
        self.pipeline_path = os.getenv('PIPELINE_PATH', '/var/lib/data-pipeline')
        self.check_interval = int(os.getenv('CHECK_INTERVAL', '60'))
        self.alerts = os.getenv('ALERTS', 'high_memory_usage,processing_delays,storage_full').split(',')
        self.metrics_enabled = os.getenv('METRICS_ENABLED', '1') == '1'
        
        self.metrics_file = Path(self.pipeline_path) / 'metrics.json'
        self.alerts_file = Path(self.pipeline_path) / 'alerts.json'
        
        # Ensure directories exist
        Path(self.pipeline_path).mkdir(parents=True, exist_ok=True)
    
    def collect_system_metrics(self):
        """Collect system resource metrics"""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage(self.pipeline_path)
            
            metrics = {
                'timestamp': datetime.now().isoformat(),
                'cpu_percent': cpu_percent,
                'memory_percent': memory.percent,
                'memory_used_gb': memory.used / (1024**3),
                'memory_available_gb': memory.available / (1024**3),
                'disk_used_gb': disk.used / (1024**3),
                'disk_free_gb': disk.free / (1024**3),
                'disk_percent': (disk.used / disk.total) * 100
            }
            
            return metrics
            
        except Exception as e:
            logger.error(f"Error collecting system metrics: {e}")
            return {}
    
    def check_pipeline_health(self):
        """Check pipeline service health"""
        try:
            health_status = {
                'timestamp': datetime.now().isoformat(),
                'services': {},
                'overall_health': 'healthy'
            }
            
            # Check pipeline services
            pipeline_services = [
                'data-collector.service',
                'data-processor.service',
                'pipeline-api.service'
            ]
            
            unhealthy_services = 0
            
            for service in pipeline_services:
                try:
                    # Simple check - in real implementation would use systemctl or dbus
                    service_status = 'unknown'
                    
                    # Mock service checking
                    if os.path.exists(f'/var/run/{service}.pid'):
                        service_status = 'active'
                    else:
                        service_status = 'inactive'
                        unhealthy_services += 1
                    
                    health_status['services'][service] = service_status
                    
                except Exception as e:
                    logger.warning(f"Could not check service {service}: {e}")
                    health_status['services'][service] = 'error'
                    unhealthy_services += 1
            
            # Determine overall health
            if unhealthy_services == 0:
                health_status['overall_health'] = 'healthy'
            elif unhealthy_services < len(pipeline_services) / 2:
                health_status['overall_health'] = 'degraded'
            else:
                health_status['overall_health'] = 'unhealthy'
            
            return health_status
            
        except Exception as e:
            logger.error(f"Error checking pipeline health: {e}")
            return {'overall_health': 'error', 'error': str(e)}
    
    def check_data_freshness(self):
        """Check if data is being processed regularly"""
        try:
            db_path = Path(self.pipeline_path) / 'pipeline.db'
            if not db_path.exists():
                return {'status': 'no_database', 'last_activity': None}
            
            conn = sqlite3.connect(db_path)
            cursor = conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='activities'"
            )
            
            if cursor.fetchone():
                # Check last activity
                cursor = conn.execute(
                    "SELECT MAX(timestamp) FROM activities"
                )
                last_timestamp = cursor.fetchone()[0]
                
                if last_timestamp:
                    last_activity = datetime.fromisoformat(last_timestamp)
                    time_since_last = datetime.now() - last_activity
                    
                    if time_since_last > timedelta(hours=1):
                        status = 'stale'
                    elif time_since_last > timedelta(minutes=15):
                        status = 'delayed'
                    else:
                        status = 'fresh'
                else:
                    status = 'no_data'
                    last_activity = None
            else:
                status = 'no_tables'
                last_activity = None
            
            conn.close()
            
            return {
                'status': status,
                'last_activity': last_activity.isoformat() if last_activity else None
            }
            
        except Exception as e:
            logger.error(f"Error checking data freshness: {e}")
            return {'status': 'error', 'error': str(e)}
    
    def generate_alerts(self, metrics, health, data_status):
        """Generate alerts based on thresholds"""
        alerts = []
        current_time = datetime.now().isoformat()
        
        # High memory usage alert
        if 'high_memory_usage' in self.alerts and metrics.get('memory_percent', 0) > 85:
            alerts.append({
                'type': 'high_memory_usage',
                'level': 'warning',
                'timestamp': current_time,
                'message': f"High memory usage: {metrics['memory_percent']:.1f}%",
                'value': metrics['memory_percent']
            })
        
        # Storage full alert
        if 'storage_full' in self.alerts and metrics.get('disk_percent', 0) > 90:
            alerts.append({
                'type': 'storage_full',
                'level': 'critical',
                'timestamp': current_time,
                'message': f"Storage nearly full: {metrics['disk_percent']:.1f}%",
                'value': metrics['disk_percent']
            })
        
        # Processing delays alert
        if 'processing_delays' in self.alerts:
            if data_status.get('status') == 'stale':
                alerts.append({
                    'type': 'processing_delays',
                    'level': 'warning',
                    'timestamp': current_time,
                    'message': "Data processing appears stale (>1 hour since last activity)",
                    'last_activity': data_status.get('last_activity')
                })
            elif data_status.get('status') == 'delayed':
                alerts.append({
                    'type': 'processing_delays',
                    'level': 'info',
                    'timestamp': current_time,
                    'message': "Data processing delayed (>15 minutes since last activity)",
                    'last_activity': data_status.get('last_activity')
                })
        
        # Service health alerts
        if health.get('overall_health') == 'unhealthy':
            alerts.append({
                'type': 'service_health',
                'level': 'critical',
                'timestamp': current_time,
                'message': "Pipeline services are unhealthy",
                'services': health.get('services', {})
            })
        elif health.get('overall_health') == 'degraded':
            alerts.append({
                'type': 'service_health',
                'level': 'warning',
                'timestamp': current_time,
                'message': "Some pipeline services are degraded",
                'services': health.get('services', {})
            })
        
        return alerts
    
    def save_metrics(self, metrics):
        """Save metrics to file"""
        try:
            # Load existing metrics
            existing_metrics = []
            if self.metrics_file.exists():
                with open(self.metrics_file, 'r') as f:
                    existing_metrics = json.load(f)
            
            # Add new metrics
            existing_metrics.append(metrics)
            
            # Keep only last 1000 entries
            if len(existing_metrics) > 1000:
                existing_metrics = existing_metrics[-1000:]
            
            # Save back to file
            with open(self.metrics_file, 'w') as f:
                json.dump(existing_metrics, f, indent=2)
                
        except Exception as e:
            logger.error(f"Error saving metrics: {e}")
    
    def save_alerts(self, alerts):
        """Save alerts to file"""
        try:
            if not alerts:
                return
                
            # Load existing alerts
            existing_alerts = []
            if self.alerts_file.exists():
                with open(self.alerts_file, 'r') as f:
                    existing_alerts = json.load(f)
            
            # Add new alerts
            existing_alerts.extend(alerts)
            
            # Keep only last 100 alerts
            if len(existing_alerts) > 100:
                existing_alerts = existing_alerts[-100:]
            
            # Save back to file
            with open(self.alerts_file, 'w') as f:
                json.dump(existing_alerts, f, indent=2)
            
            # Log alerts
            for alert in alerts:
                logger.warning(f"ALERT [{alert['level']}] {alert['type']}: {alert['message']}")
                
        except Exception as e:
            logger.error(f"Error saving alerts: {e}")
    
    def run(self):
        """Main monitoring loop"""
        logger.info(f"Starting pipeline monitor - check interval: {self.check_interval}s")
        logger.info(f"Monitoring alerts: {', '.join(self.alerts)}")
        
        while True:
            try:
                # Collect metrics
                metrics = self.collect_system_metrics()
                
                # Check health
                health = self.check_pipeline_health()
                
                # Check data freshness
                data_status = self.check_data_freshness()
                
                # Generate alerts
                alerts = self.generate_alerts(metrics, health, data_status)
                
                # Save metrics and alerts
                if self.metrics_enabled and metrics:
                    self.save_metrics({
                        **metrics,
                        'health': health,
                        'data_status': data_status
                    })
                
                if alerts:
                    self.save_alerts(alerts)
                
                # Log summary
                logger.info(f"Health check complete - Status: {health.get('overall_health', 'unknown')}, "
                           f"CPU: {metrics.get('cpu_percent', 0):.1f}%, "
                           f"Memory: {metrics.get('memory_percent', 0):.1f}%, "
                           f"Disk: {metrics.get('disk_percent', 0):.1f}%, "
                           f"Alerts: {len(alerts)}")
                
                # Wait for next check
                time.sleep(self.check_interval)
                
            except KeyboardInterrupt:
                logger.info("Monitor stopped by user")
                break
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                time.sleep(self.check_interval)

def main():
    monitor = PipelineMonitor()
    monitor.run()

if __name__ == "__main__":
    main()
