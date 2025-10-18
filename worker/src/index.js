import dotenv from 'dotenv';
import { exec } from 'child_process';
import { promisify } from 'util';

dotenv.config();

const execAsync = promisify(exec);

const DISCOVERY_INTERVAL = parseInt(process.env.DISCOVERY_INTERVAL_MINUTES || '5') * 60 * 1000;

console.log('AutoViral Discovery Worker Starting...');
console.log(`Discovery interval: ${DISCOVERY_INTERVAL / 60000} minutes`);

/**
 * Run Instagram discovery
 */
async function runDiscovery() {
  console.log(`\n[${new Date().toISOString()}] Running Instagram discovery...`);
  
  try {
    const { stdout, stderr } = await execAsync('node src/discover-instagram.js');
    if (stdout) console.log(stdout);
    if (stderr) console.error(stderr);
  } catch (error) {
    console.error('[Discovery Error]:', error.message);
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
