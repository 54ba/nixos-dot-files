#!/usr/bin/env python3
"""
Database Cleanup Script
Cleans up old data from the database
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

logger = logging.getLogger('cleanup-database')

def cleanup_database():
    """Clean up old database entries"""
    try:
        pipeline_path = Path(os.getenv('PIPELINE_PATH', '/var/lib/data-pipeline'))
        db_backend = os.getenv('DB_BACKEND', 'sqlite')
        
        logger.info(f"Cleaning up database ({db_backend}) at {pipeline_path}")
        
        # Simple cleanup - remove old temporary files
        temp_files_removed = 0
        for temp_file in pipeline_path.rglob('*.tmp'):
            temp_file.unlink()
            temp_files_removed += 1
        
        # Log cleanup results
        logger.info(f"Database cleanup completed. Removed {temp_files_removed} temporary files.")
        
        return True
        
    except Exception as e:
        logger.error(f"Error during database cleanup: {e}")
        return False

def main():
    """Main cleanup function"""
    logger.info("Database cleanup starting...")
    success = cleanup_database()
    
    if success:
        logger.info("Database cleanup completed successfully")
        sys.exit(0)
    else:
        logger.error("Database cleanup failed")
        sys.exit(1)

if __name__ == '__main__':
    main()
