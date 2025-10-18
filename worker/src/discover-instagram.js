import dotenv from 'dotenv';
import axios from 'axios';

dotenv.config();

const API_URL = process.env.API_URL || 'http://api:3000';
const AUTH_KEY = process.env.AUTH_BEARER_KEY;
const BROWSER_USE_API_KEY = process.env.BROWSER_USE_API_KEY;
const INSTAGRAM_USERNAME = process.env.INSTAGRAM_USERNAME;
const INSTAGRAM_PASSWORD = process.env.INSTAGRAM_PASSWORD;

/**
 * Discover trending topics on Instagram using Browser Use
 * Focus: SPEED over volume - get fresh, fast-moving trends
 */
async function discoverInstagramTrends() {
  console.log('[Instagram Discovery] Starting...');
  
  if (!BROWSER_USE_API_KEY) {
    console.error('[Error] BROWSER_USE_API_KEY not set');
    return;
  }
  
  try {
    // Using Browser Use API to scrape Instagram
    // Note: Browser Use provides browser automation - we'll use it to:
    // 1. Login to Instagram
    // 2. Navigate to Explore/Trending
    // 3. Extract trending hashtags and posts
    // 4. Calculate velocity (how fast they're moving)
    
    const trends = await scrapeInstagramWithBrowserUse();
    
    console.log(`[Instagram Discovery] Found ${trends.length} trends`);
    
    // Send each trend to API
    for (const trend of trends) {
      await reportTrend(trend);
    }
    
    console.log('[Instagram Discovery] Complete');
  } catch (error) {
    console.error('[Instagram Discovery] Error:', error.message);
  }
}

/**
 * Use Browser Use Cloud API to scrape Instagram trends
 * Browser Use Cloud is a managed service - no Daytona setup needed!
 * Using REST API directly since SDK has import issues
 */
async function scrapeInstagramWithBrowserUse() {
  console.log('[Browser Use Cloud] Starting Instagram discovery...');
  
  if (!BROWSER_USE_API_KEY) {
    console.error('[Browser Use Cloud] API key not configured');
    return [];
  }
  
  try {
    console.log('[Browser Use Cloud] Creating browser task via API...');
    
    // Create task using Browser Use Cloud REST API
    // Correct endpoint: /api/v1/run-task (not /v1/tasks)
    const createResponse = await axios.post('https://api.browser-use.com/api/v1/run-task', {
      task: `Go to Instagram explore page (instagram.com/explore). 
             If login is required, use username: ${INSTAGRAM_USERNAME} and password: ${INSTAGRAM_PASSWORD}.
             Extract the top 10 trending hashtags currently showing.
             For each trending hashtag, collect:
             1. Hashtag name (including #)
             2. Approximate post count  
             3. Engagement indicators (likes, comments visible)
             Return as a JSON array with format: 
             [{"hashtag": "#example", "postCount": 15000, "engagement": "high"}]`,
      result_schema: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            hashtag: { type: 'string' },
            postCount: { type: 'number' },
            engagement: { type: 'string' }
          }
        }
      }
    }, {
      headers: {
        'Authorization': `Bearer ${BROWSER_USE_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    // Log full response to debug structure
    console.log('[Browser Use Cloud] Response:', JSON.stringify(createResponse.data));
    
    // Try different possible field names
    const taskId = createResponse.data.task_id || createResponse.data.id || createResponse.data.taskId;
    
    if (!taskId) {
      throw new Error(`No task ID in response. Response: ${JSON.stringify(createResponse.data)}`);
    }
    
    console.log(`[Browser Use Cloud] Task created: ${taskId}`);
    console.log(`[Browser Use Cloud] Status: ${createResponse.data.status}`);
    if (createResponse.data.live_url) {
      console.log(`[Browser Use Cloud] Live preview: ${createResponse.data.live_url}`);
    }
    console.log('[Browser Use Cloud] Waiting for completion...');
    
    // Poll for task completion (max 3 minutes for Instagram login + scraping)
    let attempts = 0;
    const maxAttempts = 36; // 36 * 5 = 180 seconds (3 minutes)
    let result = null;
    
    while (attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 5000)); // Wait 5 seconds
      
      // Get task status - endpoint: /api/v1/get-task-status
      const statusResponse = await axios.get(`https://api.browser-use.com/api/v1/task/${taskId}`, {
        headers: {
          'Authorization': `Bearer ${BROWSER_USE_API_KEY}`
        }
      });
      
      const status = statusResponse.data.status;
      
      if (status === 'finished' || status === 'completed' || status === 'done' || status === 'success') {
        result = statusResponse.data;
        console.log('[Browser Use Cloud] Task finished! Extracting results...');
        break;
      } else if (status === 'failed' || status === 'error') {
        throw new Error(`Task failed: ${statusResponse.data.error || statusResponse.data.message || 'Unknown error'}`);
      }
      
      attempts++;
      console.log(`[Browser Use Cloud] Task status: ${status} (${attempts}/${maxAttempts})`);
    }
    
    if (!result) {
      throw new Error('Task timeout after 3 minutes');
    }
    
    console.log(`[Browser Use Cloud] Task completed successfully`);
    console.log('[Browser Use Cloud] Result keys:', Object.keys(result).join(', '));
    
    // Parse the output - try different field names
    const outputData = result.output || result.result || result.data || result.extracted_content;
    
    if (!outputData) {
      console.warn('[Browser Use Cloud] No output data in result');
      console.log('[Browser Use Cloud] Full result:', JSON.stringify(result).substring(0, 500));
      return [];
    }
    
    // Parse the output
    let rawTrends = [];
    
    if (typeof outputData === 'string') {
      try {
        rawTrends = JSON.parse(outputData);
      } catch (e) {
        console.error('[Browser Use Cloud] Failed to parse output:', e.message);
        console.log('[Browser Use Cloud] Raw output:', outputData.substring(0, 200));
        return [];
      }
    } else if (Array.isArray(outputData)) {
      rawTrends = outputData;
    } else if (typeof outputData === 'object') {
      // Output might be already parsed object
      rawTrends = [outputData];
    }
    
    console.log(`[Browser Use Cloud] Received ${rawTrends.length} raw trends`);
    
    // Transform Browser Use results into our trend format
    const trends = rawTrends
      .filter(item => item.hashtag && item.postCount)
      .slice(0, 10) // Top 10 trends
      .map(item => {
        const postCount = parseInt(item.postCount) || 0;
        const recentPosts = Math.floor(postCount * 0.12); // Estimate 12% recent
        const velocity = calculateVelocity(postCount, recentPosts);
        const engagement = (item.engagement || 'moderate').toLowerCase();
        const score = calculateScore(velocity, engagement);
        
        return {
          keyword: item.hashtag.startsWith('#') ? item.hashtag : `#${item.hashtag}`,
          source: 'instagram',
          score: score,
          reason: `${velocity} velocity with ${engagement} engagement`,
          metadata: {
            postCount: postCount,
            engagement: engagement,
            velocity: velocity,
            recentPosts: recentPosts,
            hashtags: [item.hashtag]
          }
        };
      });
    
    console.log(`[Browser Use Cloud] Processed ${trends.length} trends for reporting`);
    return trends;
    
  } catch (error) {
    console.error('[Browser Use Cloud] Error:', error.message);
    if (error.response) {
      console.error('[Browser Use Cloud] Response:', error.response.status, JSON.stringify(error.response.data));
    }
    
    // Return empty array on error - worker will retry on next cycle
    return [];
  }
}

/**
 * Calculate velocity based on post metrics
 */
function calculateVelocity(totalPosts, recentPosts) {
  const ratio = recentPosts / totalPosts;
  if (ratio > 0.15) return 'very-fast';
  if (ratio > 0.10) return 'fast';
  if (ratio > 0.05) return 'moderate';
  return 'slow';
}

/**
 * Calculate trend score (0-100)
 */
function calculateScore(velocity, engagement) {
  let score = 50; // Base score
  
  // Velocity contribution (40 points)
  switch (velocity) {
    case 'very-fast': score += 40; break;
    case 'fast': score += 30; break;
    case 'moderate': score += 20; break;
    case 'slow': score += 10; break;
  }
  
  // Engagement contribution (10 points)
  switch (engagement) {
    case 'very-high': score += 10; break;
    case 'high': score += 7; break;
    case 'moderate': score += 5; break;
    default: score += 2;
  }
  
  return Math.min(100, Math.max(0, score));
}

/**
 * Report discovered trend to API
 */
async function reportTrend(trend) {
  try {
    const response = await axios.post(
      `${API_URL}/webhook/trend`,
      trend,
      {
        headers: {
          'Authorization': `Bearer ${AUTH_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log(`[Reported] ${trend.keyword} - ${response.data.message}`);
  } catch (error) {
    if (error.response) {
      console.error(`[Report Error] ${trend.keyword}:`, error.response.data);
    } else {
      console.error(`[Report Error] ${trend.keyword}:`, error.message);
    }
  }
}

// Run discovery
discoverInstagramTrends();
