import dotenv from 'dotenv';
import { exec } from 'child_process';
import { promisify } from 'util';
import Logger from './logger.js';

dotenv.config();

const execAsync = promisify(exec);
const logger = new Logger('Worker');

const DISCOVERY_INTERVAL = parseInt(process.env.DISCOVERY_INTERVAL_MINUTES || '5') * 60 * 1000;

logger.info('AutoViral Discovery Worker Starting...');
logger.info(`Discovery interval: ${DISCOVERY_INTERVAL / 60000} minutes`);

// Lock to prevent overlapping discoveries
let isDiscoveryRunning = false;

// Shutdown flag - don't start new discoveries if shutting down
let isShuttingDown = false;

// Interval reference for cleanup
let discoveryInterval = null;

/**
 * Run Instagram discovery (with lock to prevent parallel execution)
 */
async function runDiscovery() {
  // Don't start new discoveries if shutting down
  if (isShuttingDown) {
    console.log(`\n[${new Date().toISOString()}] 🛑 Skipping - Shutdown pending`);
    return;
  }
  
  // Check if discovery is already running
  if (isDiscoveryRunning) {
    console.log(`\n[${new Date().toISOString()}] ⏭️  Skipping - Previous discovery still running`);
    return;
  }
  
  // Acquire lock
  isDiscoveryRunning = true;
  const startTime = Date.now();
  
  logger.info('🔍 Running Instagram discovery...');
  
  try {
    const { stdout, stderr } = await execAsync('node src/discover-instagram.js');
    if (stdout) console.log(stdout);
    if (stderr) console.error(stderr);
    
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    logger.success(`Discovery complete (${duration}s)`);
  } catch (error) {
    logger.error(`Discovery error: ${error.message}`);
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    logger.error(`Discovery failed (${duration}s)`);
  } finally {
    // Always release lock
    isDiscoveryRunning = false;
  }
}

// Run immediately on start
runDiscovery();

// Schedule periodic discovery
discoveryInterval = setInterval(runDiscovery, DISCOVERY_INTERVAL);

/**
 * Graceful shutdown handler
 */
async function gracefulShutdown(signal) {
  logger.warn(`📴 Received ${signal}, initiating graceful shutdown...`);
  
  // Set shutdown flag to prevent new discoveries
  isShuttingDown = true;
  
  // Stop the interval
  if (discoveryInterval) {
    clearInterval(discoveryInterval);
    logger.info('[Shutdown] Stopped discovery scheduler');
  }
  
  // Wait for current discovery to finish
  if (isDiscoveryRunning) {
    console.log('[Shutdown] ⚠️  Restart pending - Waiting for current discovery to complete...');
    console.log('[Shutdown] Discovery will finish, then worker will shutdown gracefully');
    
    // Wait up to 15 minutes for discovery to finish (Browser Use tasks can take long)
    const maxWait = 900000; // 15 minutes (900 seconds)
    const startWait = Date.now();
    let nextLogTime = 3000; // First log at 3 seconds
    
    while (isDiscoveryRunning && (Date.now() - startWait) < maxWait) {
      await new Promise(resolve => setTimeout(resolve, 1000)); // Check every second
      const elapsed = Date.now() - startWait;
      
      // Log at exponential intervals: 3s, 6s, 12s, 24s, etc.
      if (elapsed >= nextLogTime) {
        console.log(`[Shutdown] Still waiting... (${(elapsed / 1000).toFixed(1)}s)`);
        nextLogTime *= 2; // Double the interval
      }
    }
    
    if (isDiscoveryRunning) {
      console.log('[Shutdown] ⚠️  Discovery did not finish in time, forcing shutdown');
    } else {
      console.log('[Shutdown] ✅ Discovery completed');
    }
  }
  
  console.log('[Shutdown] 👋 Worker shutdown complete');
  process.exit(0);
}

// Handle graceful shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM')); // Docker stop
process.on('SIGINT', () => gracefulShutdown('SIGINT'));   // Ctrl+C
