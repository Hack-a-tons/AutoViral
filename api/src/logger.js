/**
 * Structured logging utility
 * Adds timestamp and context to all log messages
 */

/**
 * Format timestamp in ISO format with milliseconds
 */
function getTimestamp() {
  return new Date().toISOString();
}

/**
 * Format numbers for readability (shorten K/M for round thousands/millions)
 */
function formatNumber(num) {
  if (typeof num !== 'number') return num;
  
  // Check if it's a round million (e.g., 1000000, 2000000)
  if (num >= 1000000 && num % 1000000 === 0) {
    return `${num / 1000000}M`;
  }
  
  // Check if it's a round thousand (e.g., 1000, 5000)
  if (num >= 1000 && num % 1000 === 0) {
    return `${num / 1000}K`;
  }
  
  // Return as-is with commas for readability
  return num.toLocaleString();
}

/**
 * Format log message with timestamp and optional context
 */
function formatLog(level, message, context = null) {
  const timestamp = getTimestamp();
  const levelEmoji = {
    'info': 'ℹ️',
    'success': '✅',
    'error': '❌',
    'warn': '⚠️',
    'debug': '🔍'
  };
  
  const emoji = levelEmoji[level] || '';
  let logLine = `[${timestamp}] ${emoji} ${message}`;
  
  // Add context if provided (e.g., API endpoint, user ID, etc.)
  if (context) {
    if (typeof context === 'string') {
      logLine += ` | ${context}`;
    } else if (typeof context === 'object') {
      const contextStr = Object.entries(context)
        .map(([key, value]) => {
          // Format numbers for readability
          const formattedValue = typeof value === 'number' ? formatNumber(value) : value;
          return `${key}=${formattedValue}`;
        })
        .join(', ');
      logLine += ` | ${contextStr}`;
    }
  }
  
  return logLine;
}

/**
 * Logger class
 */
class Logger {
  constructor(component = '') {
    this.component = component;
  }
  
  info(message, context = null) {
    const fullContext = this.component ? { component: this.component, ...context } : context;
    console.log(formatLog('info', message, fullContext));
  }
  
  success(message, context = null) {
    const fullContext = this.component ? { component: this.component, ...context } : context;
    console.log(formatLog('success', message, fullContext));
  }
  
  error(message, context = null) {
    const fullContext = this.component ? { component: this.component, ...context } : context;
    console.error(formatLog('error', message, fullContext));
  }
  
  warn(message, context = null) {
    const fullContext = this.component ? { component: this.component, ...context } : context;
    console.warn(formatLog('warn', message, fullContext));
  }
  
  debug(message, context = null) {
    const fullContext = this.component ? { component: this.component, ...context } : context;
    console.log(formatLog('debug', message, fullContext));
  }
  
  // Special method for API calls
  api(method, endpoint, message, additionalContext = null) {
    const context = {
      component: this.component,
      api: endpoint,
      method: method.toUpperCase(),
      ...additionalContext
    };
    console.log(formatLog('info', message, context));
  }
}

export default Logger;
