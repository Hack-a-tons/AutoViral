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

// Bearer token auth middleware
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const bearerKey = process.env.AUTH_BEARER_KEY;
  
  if (!bearerKey) {
    // If no key configured, allow access (dev mode)
    return next();
  }
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid authorization header' });
  }
  
  const token = authHeader.substring(7);
  if (token !== bearerKey) {
    return res.status(401).json({ error: 'Invalid bearer token' });
  }
  
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
    
    // Parse metadata JSON
    const trendsWithMetadata = trends.map(t => ({
      ...t,
      metadata: t.metadata ? JSON.parse(t.metadata) : null
    }));
    
    res.json({
      count: trends.length,
      trends: trendsWithMetadata
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
      metadata: trend.metadata ? JSON.parse(trend.metadata) : null
    });
  } catch (error) {
    console.error('Error fetching trend:', error);
    res.status(500).json({ error: 'Failed to fetch trend' });
  }
});

// Webhook to receive new trends from discovery worker
app.post('/webhook/trend', authMiddleware, async (req, res) => {
  try {
    const { keyword, source, score, reason, metadata } = req.body;
    
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
    
    // Create new trend
    const trend = await prisma.trend.create({
      data: {
        keyword,
        source,
        score: score || 0.0,
        reason: reason || null,
        metadata: metadata ? JSON.stringify(metadata) : null,
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
