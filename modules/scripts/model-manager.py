#!/usr/bin/env python3
"""
Model Manager Service
Manages AI models for the orchestrator
"""

import os
import sys
import json
import logging
import requests
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/lib/ai-orchestrator/logs/model-manager.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger('model-manager')

class ModelManager:
    def __init__(self):
        self.ai_endpoint = os.getenv('AI_ENDPOINT', 'http://localhost:11434')
        self.ai_models = os.getenv('AI_MODELS', 'llama3.1,codellama,vision').split(',')
        self.model_path = Path(os.getenv('MODEL_PATH', '/var/lib/ai-orchestrator/models'))
        self.model_path.mkdir(parents=True, exist_ok=True)
    
    def check_ollama_service(self):
        """Check if Ollama service is running"""
        try:
            response = requests.get(f"{self.ai_endpoint}/api/tags", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def list_available_models(self):
        """List available models in Ollama"""
        try:
            response = requests.get(f"{self.ai_endpoint}/api/tags", timeout=10)
            if response.status_code == 200:
                data = response.json()
                return [model['name'] for model in data.get('models', [])]
            return []
        except Exception as e:
            logger.error(f"Error listing models: {e}")
            return []
    
    def pull_model(self, model_name):
        """Pull a model from Ollama registry"""
        try:
            logger.info(f"Pulling model: {model_name}")
            response = requests.post(
                f"{self.ai_endpoint}/api/pull",
                json={"name": model_name},
                stream=True,
                timeout=3600  # 1 hour timeout for model downloads
            )
            
            if response.status_code == 200:
                for line in response.iter_lines():
                    if line:
                        try:
                            data = json.loads(line)
                            if 'status' in data:
                                logger.info(f"Model {model_name}: {data['status']}")
                            if data.get('status') == 'success':
                                logger.info(f"Successfully pulled model: {model_name}")
                                return True
                        except json.JSONDecodeError:
                            continue
            else:
                logger.error(f"Failed to pull model {model_name}: {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"Error pulling model {model_name}: {e}")
            return False
    
    def ensure_models(self):
        """Ensure required models are available"""
        if not self.check_ollama_service():
            logger.warning("Ollama service not available, skipping model management")
            return
        
        available_models = self.list_available_models()
        logger.info(f"Available models: {available_models}")
        
        for model in self.ai_models:
            model = model.strip()
            if not model:
                continue
                
            # Check if model is already available
            model_available = any(model in available for available in available_models)
            
            if not model_available:
                logger.info(f"Model {model} not found, attempting to pull...")
                success = self.pull_model(model)
                if success:
                    logger.info(f"Successfully ensured model: {model}")
                else:
                    logger.warning(f"Failed to pull model: {model}")
            else:
                logger.info(f"Model {model} already available")
    
    def run(self):
        """Main model manager execution"""
        logger.info("Model Manager starting...")
        self.ensure_models()
        logger.info("Model Manager completed")

def main():
    manager = ModelManager()
    manager.run()

if __name__ == '__main__':
    main()
