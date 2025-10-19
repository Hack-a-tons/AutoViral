import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TRACKING_FILE = path.join(__dirname, '../data/trending-posts.json');
const MAX_POSTS_PER_HASHTAG = 100;

/**
 * Load previously tracked posts
 */
export function loadTrackedPosts() {
  try {
    // Ensure data directory exists
    const dataDir = path.dirname(TRACKING_FILE);
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }
    
    if (fs.existsSync(TRACKING_FILE)) {
      const data = fs.readFileSync(TRACKING_FILE, 'utf8');
      return JSON.parse(data);
    }
  } catch (error) {
    console.error('[Trending Tracker] Error loading tracked posts:', error.message);
  }
  
  return {}; // { hashtag: { posts: [...], lastChecked: timestamp } }
}

/**
 * Save tracked posts
 */
export function saveTrackedPosts(trackedPosts) {
  try {
    const dataDir = path.dirname(TRACKING_FILE);
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }
    
    fs.writeFileSync(TRACKING_FILE, JSON.stringify(trackedPosts, null, 2), 'utf8');
  } catch (error) {
    console.error('[Trending Tracker] Error saving tracked posts:', error.message);
  }
}

/**
 * Calculate growth velocity by comparing current and previous posts
 */
export function calculateGrowthVelocity(hashtag, currentPosts, currentMetrics) {
  const tracked = loadTrackedPosts();
  const previous = tracked[hashtag];
  
  if (!previous) {
    // First time seeing this hashtag - mark as new
    return {
      velocity: 'new',
      growth: 0,
      isNew: true
    };
  }
  
  const now = Date.now();
  const timeDiff = now - previous.lastChecked; // milliseconds
  const hoursDiff = timeDiff / (1000 * 60 * 60); // hours
  
  if (hoursDiff < 0.1) {
    // Too soon to check again (< 6 minutes)
    return {
      velocity: 'unknown',
      growth: 0,
      isNew: false
    };
  }
  
  // Calculate post count growth
  const previousCount = previous.postCount || 0;
  const currentCount = currentMetrics.postCount || 0;
  const postGrowth = currentCount - previousCount;
  const postGrowthRate = postGrowth / hoursDiff; // posts per hour
  
  // Calculate engagement growth (likes on top posts)
  const previousTopLikes = previous.topPostLikes || 0;
  const currentTopLikes = currentMetrics.topPostLikes || 0;
  const likeGrowth = currentTopLikes - previousTopLikes;
  const likeGrowthRate = likeGrowth / hoursDiff; // likes per hour
  
  // Determine velocity based on growth rates
  let velocity = 'slow';
  let growthScore = 0;
  
  // Post growth rate (weighted 60%)
  if (postGrowthRate > 10000) { // >10K posts/hour
    growthScore += 60;
  } else if (postGrowthRate > 1000) { // >1K posts/hour
    growthScore += 45;
  } else if (postGrowthRate > 100) { // >100 posts/hour
    growthScore += 30;
  } else if (postGrowthRate > 10) { // >10 posts/hour
    growthScore += 15;
  }
  
  // Engagement growth rate (weighted 40%)
  if (likeGrowthRate > 100000) { // >100K likes/hour on top post
    growthScore += 40;
  } else if (likeGrowthRate > 10000) { // >10K likes/hour
    growthScore += 30;
  } else if (likeGrowthRate > 1000) { // >1K likes/hour
    growthScore += 20;
  } else if (likeGrowthRate > 100) { // >100 likes/hour
    growthScore += 10;
  }
  
  // Determine velocity category
  if (growthScore >= 75) velocity = 'very-fast';
  else if (growthScore >= 50) velocity = 'fast';
  else if (growthScore >= 25) velocity = 'moderate';
  else velocity = 'slow';
  
  return {
    velocity,
    growth: growthScore,
    isNew: false,
    postGrowth,
    postGrowthRate: Math.round(postGrowthRate),
    likeGrowth,
    likeGrowthRate: Math.round(likeGrowthRate),
    hoursSinceLastCheck: Math.round(hoursDiff * 10) / 10
  };
}

/**
 * Update tracked posts for a hashtag
 */
export function updateTrackedPosts(hashtag, posts, metrics) {
  const tracked = loadTrackedPosts();
  
  // Keep only top 100 posts (sorted by likes, most recent first)
  const topPosts = posts.slice(0, MAX_POSTS_PER_HASHTAG);
  
  tracked[hashtag] = {
    posts: topPosts,
    postCount: metrics.postCount,
    topPostLikes: metrics.topPostLikes,
    lastChecked: Date.now(),
    updatedAt: new Date().toISOString()
  };
  
  // Clean up old hashtags (older than 7 days)
  const sevenDaysAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
  for (const [key, value] of Object.entries(tracked)) {
    if (value.lastChecked < sevenDaysAgo) {
      delete tracked[key];
    }
  }
  
  saveTrackedPosts(tracked);
}

/**
 * Get stats about tracked hashtags
 */
export function getTrackingStats() {
  const tracked = loadTrackedPosts();
  const hashtags = Object.keys(tracked);
  
  let totalPosts = 0;
  for (const data of Object.values(tracked)) {
    totalPosts += (data.posts || []).length;
  }
  
  return {
    trackedHashtags: hashtags.length,
    totalTrackedPosts: totalPosts,
    hashtags: hashtags
  };
}
