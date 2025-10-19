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

/**
 * Run Instagram discovery (with lock to prevent parallel execution)
 */
async function runDiscovery() {
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
setInterval(runDiscovery, DISCOVERY_INTERVAL);

// Keep process alive
process.on('SIGINT', () => {
  console.log('\nWorker shutting down...');
  process.exit();
});
