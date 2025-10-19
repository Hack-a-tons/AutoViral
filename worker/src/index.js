import dotenv from 'dotenv';
import { exec } from 'child_process';
import { promisify } from 'util';

dotenv.config();

const execAsync = promisify(exec);

const DISCOVERY_INTERVAL = parseInt(process.env.DISCOVERY_INTERVAL_MINUTES || '5') * 60 * 1000;

console.log('AutoViral Discovery Worker Starting...');
console.log(`Discovery interval: ${DISCOVERY_INTERVAL / 60000} minutes`);

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
  
  console.log(`\n[${new Date().toISOString()}] 🔍 Running Instagram discovery...`);
  
  try {
    const { stdout, stderr } = await execAsync('node src/discover-instagram.js');
    if (stdout) console.log(stdout);
    if (stderr) console.error(stderr);
    
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log(`[${new Date().toISOString()}] ✅ Discovery complete (${duration}s)`);
  } catch (error) {
    console.error('[Discovery Error]:', error.message);
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log(`[${new Date().toISOString()}] ❌ Discovery failed (${duration}s)`);
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
  console.log(`\n[${new Date().toISOString()}] 📴 Received ${signal}, initiating graceful shutdown...`);
  
  // Set shutdown flag to prevent new discoveries
  isShuttingDown = true;
  
  // Stop the interval
  if (discoveryInterval) {
    clearInterval(discoveryInterval);
    console.log('[Shutdown] Stopped discovery scheduler');
  }
  
  // Wait for current discovery to finish
  if (isDiscoveryRunning) {
    console.log('[Shutdown] Waiting for current discovery to complete...');
    
    // Wait up to 30 seconds for discovery to finish
    const maxWait = 30000; // 30 seconds
    const startWait = Date.now();
    
    while (isDiscoveryRunning && (Date.now() - startWait) < maxWait) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      const elapsed = ((Date.now() - startWait) / 1000).toFixed(1);
      console.log(`[Shutdown] Still waiting... (${elapsed}s)`);
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
