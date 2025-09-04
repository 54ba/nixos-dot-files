#!/usr/bin/env python3

import os
import sys
import json
import sqlite3
import logging
import datetime
from pathlib import Path
from typing import List, Dict, Any

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('ml-trainer')

class MLTrainer:
    def __init__(self):
        self.pipeline_path = os.getenv('PIPELINE_PATH', '/var/lib/data-pipeline')
        self.models = os.getenv('ML_MODELS', 'activity_classifier').split(',')
        self.db_backend = os.getenv('DB_BACKEND', 'sqlite')
        self.models_dir = Path(self.pipeline_path) / 'models'
        self.models_dir.mkdir(parents=True, exist_ok=True)
        
    def load_training_data(self, model_type: str) -> Dict[str, Any]:
        """Load training data for specific model type"""
        try:
            if self.db_backend == 'sqlite':
                db_path = Path(self.pipeline_path) / 'pipeline.db'
                conn = sqlite3.connect(db_path)
                
                if model_type == 'activity_classifier':
                    query = "SELECT * FROM activities ORDER BY timestamp DESC LIMIT 10000"
                elif model_type == 'pattern_detector':
                    query = "SELECT * FROM patterns ORDER BY timestamp DESC LIMIT 10000"
                elif model_type == 'anomaly_detector':
                    query = "SELECT * FROM anomalies ORDER BY timestamp DESC LIMIT 10000"
                else:
                    logger.warning(f"Unknown model type: {model_type}")
                    return {}
                
                cursor = conn.execute(query)
                data = cursor.fetchall()
                conn.close()
                
                return {
                    'data': data,
                    'count': len(data),
                    'model_type': model_type
                }
                
        except Exception as e:
            logger.error(f"Error loading training data for {model_type}: {e}")
            return {}
    
    def train_model(self, model_type: str, data: Dict[str, Any]) -> bool:
        """Train a specific model"""
        try:
            logger.info(f"Training {model_type} model with {data.get('count', 0)} samples")
            
            # Mock training process - in real implementation, this would use actual ML libraries
            import time
            import random
            
            # Simulate training time
            time.sleep(random.uniform(1, 3))
            
            # Save model metadata
            model_info = {
                'model_type': model_type,
                'trained_at': datetime.datetime.now().isoformat(),
                'data_samples': data.get('count', 0),
                'version': f"v{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}",
                'accuracy': random.uniform(0.85, 0.95),  # Mock accuracy
                'status': 'trained'
            }
            
            model_file = self.models_dir / f"{model_type}_model.json"
            with open(model_file, 'w') as f:
                json.dump(model_info, f, indent=2)
            
            logger.info(f"Successfully trained {model_type} model - accuracy: {model_info['accuracy']:.3f}")
            return True
            
        except Exception as e:
            logger.error(f"Error training {model_type} model: {e}")
            return False
    
    def cleanup_old_models(self):
        """Remove old model versions"""
        try:
            for model_file in self.models_dir.glob("*.json"):
                # Keep only latest 5 versions of each model
                model_type = model_file.stem.replace('_model', '')
                versions = list(self.models_dir.glob(f"{model_type}_model_v*.json"))
                
                if len(versions) > 5:
                    # Sort by modification time and remove oldest
                    versions.sort(key=lambda x: x.stat().st_mtime, reverse=True)
                    for old_version in versions[5:]:
                        old_version.unlink()
                        logger.info(f"Removed old model version: {old_version.name}")
                        
        except Exception as e:
            logger.error(f"Error cleaning up old models: {e}")
    
    def run(self):
        """Main training loop"""
        logger.info("Starting ML model training session")
        
        trained_models = []
        failed_models = []
        
        for model_type in self.models:
            model_type = model_type.strip()
            if not model_type:
                continue
                
            logger.info(f"Processing model: {model_type}")
            
            # Load training data
            data = self.load_training_data(model_type)
            if not data:
                logger.warning(f"No training data available for {model_type}")
                failed_models.append(model_type)
                continue
            
            # Train model
            if self.train_model(model_type, data):
                trained_models.append(model_type)
            else:
                failed_models.append(model_type)
        
        # Cleanup old models
        self.cleanup_old_models()
        
        # Log results
        logger.info(f"Training session complete - Trained: {len(trained_models)}, Failed: {len(failed_models)}")
        
        if trained_models:
            logger.info(f"Successfully trained models: {', '.join(trained_models)}")
        
        if failed_models:
            logger.warning(f"Failed to train models: {', '.join(failed_models)}")
        
        return len(failed_models) == 0

def main():
    trainer = MLTrainer()
    success = trainer.run()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
