import dotenv from 'dotenv';
import axios from 'axios';
import { calculateGrowthVelocity, updateTrackedPosts, getTrackingStats } from './trending-tracker.js';

dotenv.config();

const API_URL = process.env.API_URL || 'http://api:3000';
const AUTH_KEY = process.env.AUTH_BEARER_KEY;
const BROWSER_USE_API_KEY = process.env.BROWSER_USE_API_KEY;
const INSTAGRAM_USERNAME = process.env.INSTAGRAM_USERNAME;
const INSTAGRAM_PASSWORD = process.env.INSTAGRAM_PASSWORD;

// Track current running task to cancel on restart
let currentTaskId = null;

// Shutdown flag for graceful shutdown
let isShuttingDown = false;

/**
 * Cancel current Browser Use task
 */
async function cancelCurrentTask() {
  if (!currentTaskId || !BROWSER_USE_API_KEY) {
    return;
  }
  
  console.log(`[Shutdown] Cancelling Browser Use task: ${currentTaskId}`);
  try {
    await axios.post(
      `https://api.browser-use.com/api/v1/task/${currentTaskId}/cancel`,
      {},
      {
        headers: {
          'Authorization': `Bearer ${BROWSER_USE_API_KEY}`
        }
      }
    );
    console.log('[Shutdown] ✅ Browser Use task cancelled');
  } catch (error) {
    console.log('[Shutdown] Browser Use task may have already finished');
  }
  currentTaskId = null;
}

// Handle shutdown signals
process.on('SIGTERM', async () => {
  console.log('[Shutdown] 📴 Received SIGTERM in discovery process');
  isShuttingDown = true;
  await cancelCurrentTask();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('[Shutdown] 📴 Received SIGINT in discovery process');
  isShuttingDown = true;
  await cancelCurrentTask();
  process.exit(0);
});

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
    
    // Send each trend to API and collect stats
    let reported = 0;
    let duplicates = 0;
    let totalPosts = 0;
    let totalLikes = 0;
    
    for (const trend of trends) {
      const result = await reportTrend(trend);
      if (result && result.created) {
        reported++;
        if (trend.metadata?.postCount) totalPosts += trend.metadata.postCount;
        if (trend.examplePosts?.[0]?.likes) totalLikes += trend.examplePosts[0].likes;
      } else {
        duplicates++;
      }
    }
    
    // Display stats
    const trackingStats = getTrackingStats();
    console.log('\n📊 Discovery Stats:');
    console.log(`   • Trends found: ${trends.length}`);
    console.log(`   • New trends: ${reported}`);
    console.log(`   • Duplicates: ${duplicates}`);
    if (totalPosts > 0) console.log(`   • Total posts: ${totalPosts.toLocaleString()}`);
    if (totalLikes > 0) console.log(`   • Avg top post likes: ${Math.round(totalLikes / reported).toLocaleString()}`);
    console.log(`   • Tracking ${trackingStats.trackedHashtags} hashtags (${trackingStats.totalTrackedPosts} posts)`);
    console.log('[Instagram Discovery] Complete\n');
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
  
  // Cancel previous task if still running
  if (currentTaskId) {
    console.log(`[Browser Use Cloud] Cancelling previous task: ${currentTaskId}`);
    try {
      await axios.post(`https://api.browser-use.com/api/v1/task/${currentTaskId}/cancel`, {}, {
        headers: {
          'Authorization': `Bearer ${BROWSER_USE_API_KEY}`
        }
      });
      console.log('[Browser Use Cloud] Previous task cancelled');
    } catch (e) {
      console.log('[Browser Use Cloud] Could not cancel previous task (may have already finished)');
    }
    currentTaskId = null;
  }
  
  try {
    console.log('[Browser Use Cloud] Creating browser task via API...');
    
    // Create task using Browser Use Cloud REST API
    // Correct endpoint: /api/v1/run-task (not /v1/tasks)
    const createResponse = await axios.post('https://api.browser-use.com/api/v1/run-task', {
      task: `CRITICAL: Your response MUST be ONLY valid JSON with NO explanatory text before or after.

IMPORTANT: Work at HUMAN SPEED to avoid rate limiting!
- Wait 3-5 seconds between actions
- Scroll slowly and naturally
- Random pauses

Go to instagram.com/explore (public page, DO NOT login).

DON'T click into individual hashtags (they require login).
Instead, scrape the visible explore page:

1. Look at the trending topics/hashtags shown on the main explore page
2. For each visible trending topic (aim for 5-8):
   - Get the hashtag name
   - Estimate popularity from position/size (top = high, side = medium, bottom = low)
   - If post count is visible, note it (convert "1.5M" → 1500000, "150K" → 150000)
3. For visible post thumbnails:
   - Hover over posts to see like counts if possible
   - Note a few example post URLs
4. Scroll down slowly to see more trends (WAIT 3 seconds between scrolls)

Estimate data if exact numbers not visible:
- Top trending: postCount ~1000000, engagement "high"
- Medium trending: postCount ~500000, engagement "medium"  
- Lower trending: postCount ~100000, engagement "low"

YOUR ENTIRE RESPONSE MUST BE THIS JSON ARRAY (no text before/after):
[{"hashtag":"#example","postCount":1000000,"engagement":"high","topPostLikes":50000,"examplePostUrl":"https://instagram.com/p/ABC123/"}]

Rules:
- Start response with [ and end with ]
- NO explanatory text ("Here is", "I found", "I was unable", etc.)
- Just pure JSON array
- Include # in hashtags
- Use numbers not strings with K/M
- If you can't get data, return empty array: []
- DO NOT return error messages in plain text`,
      result_schema: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            hashtag: { type: 'string' },
            postCount: { type: 'number' },
            engagement: { type: 'string' },
            topPostLikes: { type: 'number' },
            examplePostUrl: { type: 'string' }
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
    
    // Track this task so we can cancel it if needed
    currentTaskId = taskId;
    
    console.log(`[Browser Use Cloud] Task created: ${taskId}`);
    console.log(`[Browser Use Cloud] Status: ${createResponse.data.status}`);
    if (createResponse.data.live_url) {
      console.log(`[Browser Use Cloud] Live preview: ${createResponse.data.live_url}`);
    }
    console.log('[Browser Use Cloud] Waiting for completion (working at human speed to avoid rate limits)...');
    
    // Poll for task completion (max 5 minutes - working at human speed takes longer)
    let attempts = 0;
    const maxAttempts = 60; // 60 * 5 = 300 seconds (5 minutes)
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
      // Check if Browser Use returned an error message instead of JSON
      if (outputData.startsWith('I was unable') || 
          outputData.startsWith('The task could not') ||
          outputData.startsWith('I successfully')) {
        console.error('[Browser Use Cloud] ❌ Browser Use returned error message instead of JSON');
        console.log('[Browser Use Cloud] Error:', outputData.substring(0, 300));
        console.log('[Browser Use Cloud] Tip: Instagram may be blocking access. Try different approach.');
        return [];
      }
      
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
    
    // Transform Browser Use results into our trend format with enhanced data
    const trends = rawTrends
      .filter(item => item.hashtag && item.postCount)
      .slice(0, 10) // Top 10 trends
      .map(item => {
        const postCount = parseInt(item.postCount) || 0;
        const topPostLikes = parseInt(item.topPostLikes) || 0;
        const engagement = (item.engagement || 'moderate').toLowerCase();
        
        // Calculate REAL growth velocity by comparing with previous discovery
        const growthData = calculateGrowthVelocity(item.hashtag, [], {
          postCount,
          topPostLikes
        });
        
        const velocity = growthData.velocity;
        const score = calculateScore(velocity, engagement, growthData.growth);
        
        // Update tracked posts for next comparison
        updateTrackedPosts(item.hashtag, [], {
          postCount,
          topPostLikes
        });
        
        // Build enhanced metadata with growth tracking
        const metadata = {
          postCount: postCount,
          engagement: engagement,
          velocity: velocity,
          hashtags: [item.hashtag],
          avgLikes: topPostLikes > 0 ? topPostLikes : null,
          topCreators: [],
          // Growth tracking data
          isNew: growthData.isNew,
          postGrowthRate: growthData.postGrowthRate,
          likeGrowthRate: growthData.likeGrowthRate,
          hoursSinceLastCheck: growthData.hoursSinceLastCheck
        };
        
        // Build example posts if we have data
        const examplePosts = [];
        if (item.examplePostUrl && topPostLikes > 0) {
          examplePosts.push({
            postUrl: item.examplePostUrl,
            likes: topPostLikes,
            thumbnailUrl: null // Browser Use didn't capture this
          });
        }
        
        // Build platform data
        const platformData = {
          instagram: {
            hashtagUrl: `https://instagram.com/explore/tags/${item.hashtag.replace('#', '')}/`,
            postCount: postCount,
            avgEngagement: topPostLikes > 0 ? (topPostLikes / postCount * 100).toFixed(2) : null
          }
        };
        
        return {
          keyword: item.hashtag.startsWith('#') ? item.hashtag : `#${item.hashtag}`,
          source: 'instagram',
          score: score,
          reason: `${velocity} velocity with ${engagement} engagement`,
          metadata: metadata,
          examplePosts: examplePosts.length > 0 ? examplePosts : undefined,
          platformData: platformData
        };
      });
    
    console.log(`[Browser Use Cloud] Processed ${trends.length} trends for reporting`);
    
    // Clear task ID on success
    currentTaskId = null;
    
    return trends;
    
  } catch (error) {
    console.error('[Browser Use Cloud] Error:', error.message);
    if (error.response) {
      console.error('[Browser Use Cloud] Response:', error.response.status, JSON.stringify(error.response.data));
    }
    
    // Clear task ID on error (will be cancelled on next run if still active)
    currentTaskId = null;
    
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
 * Now uses real growth data instead of estimates
 */
function calculateScore(velocity, engagement, growthScore = 0) {
  let score = 20; // Base score
  
  // Growth/Velocity contribution (60 points) - prioritize TRENDING
  if (velocity === 'new') {
    score += 30; // New hashtags get moderate score
  } else if (growthScore > 0) {
    score += growthScore; // Use actual growth score (0-100)
  } else {
    // Fallback to velocity if no growth data yet
    switch (velocity) {
      case 'very-fast': score += 50; break;
      case 'fast': score += 35; break;
      case 'moderate': score += 20; break;
      case 'slow': score += 5; break;
    }
  }
  
  // Engagement contribution (20 points)
  switch (engagement) {
    case 'very-high': score += 20; break;
    case 'high': score += 15; break;
    case 'medium': score += 10; break;
    case 'moderate': score += 8; break;
    default: score += 3;
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
    
    const isDuplicate = response.data.message.includes('Duplicate') || response.data.message.includes('already exists');
    console.log(`[Reported] ${trend.keyword} - ${response.data.message}`);
    
    return { created: !isDuplicate };
  } catch (error) {
    if (error.response) {
      console.error(`[Report Error] ${trend.keyword}:`, error.response.data);
    } else {
      console.error(`[Report Error] ${trend.keyword}:`, error.message);
    }
    return { created: false };
  }
}

// Run discovery
discoverInstagramTrends();
