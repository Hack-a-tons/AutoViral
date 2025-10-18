import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config();

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Bearer token auth middleware (disabled for public access)
const authMiddleware = (req, res, next) => {
  // Public API - no authentication required
  next();
};

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    database: 'connected'
  });
});

// Get trends
app.get('/trends', authMiddleware, async (req, res) => {
  try {
    const { status, source, since, limit = 50 } = req.query;
    
    const where = {};
    if (status) where.status = status;
    if (source) where.source = source;
    
    // Filter by time if 'since' is provided (e.g., "1h", "30m", "2d")
    if (since) {
      const now = new Date();
      const match = since.match(/^(\d+)([smhd])$/);
      if (match) {
        const value = parseInt(match[1]);
        const unit = match[2];
        const msMap = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
        const sinceDate = new Date(now.getTime() - value * msMap[unit]);
        where.discoveredAt = { gte: sinceDate };
      }
    }
    
    const trends = await prisma.trend.findMany({
      where,
      orderBy: { discoveredAt: 'desc' },
      take: parseInt(limit)
    });
    
    // Parse JSON fields
    const trendsWithParsedData = trends.map(t => ({
      ...t,
      metadata: t.metadata ? JSON.parse(t.metadata) : null,
      media: t.media ? JSON.parse(t.media) : null,
      examplePosts: t.examplePosts ? JSON.parse(t.examplePosts) : null,
      platformData: t.platformData ? JSON.parse(t.platformData) : null,
      analysis: t.analysis ? JSON.parse(t.analysis) : null
    }));
    
    res.json({
      count: trends.length,
      trends: trendsWithParsedData
    });
  } catch (error) {
    console.error('Error fetching trends:', error);
    res.status(500).json({ error: 'Failed to fetch trends' });
  }
});

// Get single trend
app.get('/trends/:id', authMiddleware, async (req, res) => {
  try {
    const trend = await prisma.trend.findUnique({
      where: { id: req.params.id }
    });
    
    if (!trend) {
      return res.status(404).json({ error: 'Trend not found' });
    }
    
    res.json({
      ...trend,
      metadata: trend.metadata ? JSON.parse(trend.metadata) : null,
      media: trend.media ? JSON.parse(trend.media) : null,
      examplePosts: trend.examplePosts ? JSON.parse(trend.examplePosts) : null,
      platformData: trend.platformData ? JSON.parse(trend.platformData) : null,
      analysis: trend.analysis ? JSON.parse(trend.analysis) : null
    });
  } catch (error) {
    console.error('Error fetching trend:', error);
    res.status(500).json({ error: 'Failed to fetch trend' });
  }
});

// Webhook to receive new trends from discovery worker
app.post('/webhook/trend', authMiddleware, async (req, res) => {
  try {
    const { 
      keyword, source, score, reason, metadata,
      thumbnailUrl, media, examplePosts, platformData, analysis
    } = req.body;
    
    if (!keyword || !source) {
      return res.status(400).json({ error: 'keyword and source are required' });
    }
    
    // Check for duplicates (same keyword from same source in last hour)
    const oneHourAgo = new Date(Date.now() - 3600000);
    const existing = await prisma.trend.findFirst({
      where: {
        keyword,
        source,
        discoveredAt: { gte: oneHourAgo }
      }
    });
    
    if (existing) {
      return res.json({ message: 'Duplicate trend (already exists)', id: existing.id });
    }
    
    // Create new trend with enhanced data
    const trend = await prisma.trend.create({
      data: {
        keyword,
        source,
        score: score || 0.0,
        reason: reason || null,
        metadata: metadata ? JSON.stringify(metadata) : null,
        thumbnailUrl: thumbnailUrl || null,
        media: media ? JSON.stringify(media) : null,
        examplePosts: examplePosts ? JSON.stringify(examplePosts) : null,
        platformData: platformData ? JSON.stringify(platformData) : null,
        analysis: analysis ? JSON.stringify(analysis) : null,
        discoveredAt: new Date()
      }
    });
    
    res.status(201).json({ message: 'Trend created', id: trend.id });
  } catch (error) {
    console.error('Error creating trend:', error);
    res.status(500).json({ error: 'Failed to create trend' });
  }
});

// Stop a trend
app.post('/stop/trend/:id', authMiddleware, async (req, res) => {
  try {
    const trend = await prisma.trend.update({
      where: { id: req.params.id },
      data: { status: 'stopped' }
    });
    
    res.json({ message: 'Trend stopped', id: trend.id });
  } catch (error) {
    console.error('Error stopping trend:', error);
    res.status(500).json({ error: 'Failed to stop trend' });
  }
});

// Stop by keyword
app.post('/stop/keyword', authMiddleware, async (req, res) => {
  try {
    const { keyword } = req.body;
    
    if (!keyword) {
      return res.status(400).json({ error: 'keyword is required' });
    }
    
    const result = await prisma.trend.updateMany({
      where: { 
        keyword,
        status: { not: 'stopped' }
      },
      data: { status: 'stopped' }
    });
    
    res.json({ message: `Stopped ${result.count} trends with keyword: ${keyword}` });
  } catch (error) {
    console.error('Error stopping keyword:', error);
    res.status(500).json({ error: 'Failed to stop keyword' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`AutoViral API running on port ${PORT}`);
  console.log(`Health: http://localhost:${PORT}/health`);
  console.log(`Trends: http://localhost:${PORT}/trends`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit();
});
