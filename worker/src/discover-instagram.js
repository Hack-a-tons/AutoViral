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
 * Use Browser Use API to scrape Instagram trends
 * Direct API integration using axios
 */
async function scrapeInstagramWithBrowserUse() {
  console.log('[Browser Use] Starting real Instagram discovery...');
  
  if (!BROWSER_USE_API_KEY) {
    console.error('[Browser Use] API key not configured');
    return [];
  }
  
  try {
    // Call Browser Use API to scrape Instagram
    console.log('[Browser Use] Creating task for Instagram explore...');
    
    const response = await axios.post('https://api.browseruse.com/v1/execute', {
      task: `Navigate to Instagram explore page and extract trending hashtags. 
             For each trending hashtag, get: 
             1. Hashtag name
             2. Post count
             3. Recent activity indicators
             4. Engagement level (likes, comments)
             Return as JSON array with fields: hashtag, postCount, recentPosts, engagement`,
      browser: 'chromium',
      headless: true,
      credentials: {
        instagram: {
          username: INSTAGRAM_USERNAME,
          password: INSTAGRAM_PASSWORD
        }
      },
      timeout: 60000
    }, {
      headers: {
        'Authorization': `Bearer ${BROWSER_USE_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.data || !response.data.result) {
      console.warn('[Browser Use] No data returned from API');
      return [];
    }
    
    console.log(`[Browser Use] Received ${response.data.result.length} raw trends`);
    
    // Transform Browser Use results into our trend format
    const trends = response.data.result
      .filter(item => item.hashtag && item.postCount)
      .slice(0, 10) // Top 10 trends
      .map(item => {
        const postCount = parseInt(item.postCount) || 0;
        const recentPosts = parseInt(item.recentPosts) || Math.floor(postCount * 0.1);
        const velocity = calculateVelocity(postCount, recentPosts);
        const score = calculateScore(velocity, item.engagement);
        
        return {
          keyword: item.hashtag.startsWith('#') ? item.hashtag : `#${item.hashtag}`,
          source: 'instagram',
          score: score,
          reason: `${velocity} velocity with ${item.engagement || 'moderate'} engagement`,
          metadata: {
            postCount: postCount,
            engagement: item.engagement || 'moderate',
            velocity: velocity,
            recentPosts: recentPosts,
            hashtags: [item.hashtag]
          }
        };
      });
    
    console.log(`[Browser Use] Processed ${trends.length} trends`);
    return trends;
    
  } catch (error) {
    console.error('[Browser Use] Error:', error.message);
    if (error.response) {
      console.error('[Browser Use] API Response:', error.response.status, error.response.data);
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
