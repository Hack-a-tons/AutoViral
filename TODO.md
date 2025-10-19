# AutoViral Roadmap

Implementation roadmap broken into phases. Each phase builds on the previous one.

---

## ✅ Phase 1: Discovery System (COMPLETE - Oct 2025)

**Status:** Live and operational at `viral.biaz.hurated.com`

### Completed Features

- [x] Browser Use Cloud integration
  - [x] REST API client (no SDK needed)
  - [x] Instagram public explore scraping (no login)
  - [x] Automatic task polling and status checks
  - [x] Error handling and retries

- [x] Trend Discovery Worker
  - [x] Configurable discovery interval (1-5 minutes)
  - [x] Velocity scoring algorithm
  - [x] Duplicate detection (1-hour window)
  - [x] Automatic reporting to API

- [x] REST API (Express + SQLite)
  - [x] GET /health
  - [x] GET /trends (with filtering)
  - [x] GET /trends/:id
  - [x] POST /webhook/trend
  - [x] POST /stop/trend/:id
  - [x] POST /stop/keyword

- [x] Enhanced Database Schema
  - [x] Core fields (keyword, source, status, score)
  - [x] Enhanced fields (thumbnailUrl, media, examplePosts, platformData, analysis)
  - [x] JSON field parsing
  - [x] Automatic timestamps

- [x] Deployment Infrastructure
  - [x] Docker Compose setup
  - [x] SSH-based deployment script
  - [x] Server monitoring scripts
  - [x] Automated builds and restarts

- [x] Scripts & Tools
  - [x] `set-discovery-interval.sh` - Configure discovery frequency
  - [x] `deploy.sh` - One-command deployment
  - [x] `server-logs.sh` - View service logs
  - [x] `server-status.sh` - Check deployment
  - [x] `trends.sh` - View discovered trends

### Performance Metrics

- ✅ 10 trends discovered per cycle
- ✅ ~2 minute discovery duration
- ✅ 100% success rate
- ✅ Sub-100ms API latency
- ✅ 24/7 uptime

---

## 🔄 Phase 2: Selection Engine & Content Intelligence (NEXT)

**Timeline:** Q1 2026  
**Goal:** Filter and prioritize trends for content generation

### 2.1 LLM Integration

- [ ] OpenAI/Gemini/Claude provider switcher
- [ ] Prompt management system
  - [ ] `/prompts/selection/*.txt`
  - [ ] Version control for prompts
  - [ ] A/B testing framework

- [ ] Trend Analysis
  - [ ] Category classification (art, fashion, tech, etc.)
  - [ ] Virality prediction scoring
  - [ ] Audience demographic estimation
  - [ ] Optimal posting time recommendations

### 2.2 Content Safety

- [ ] Safety filter prompts
  - [ ] Profanity detection
  - [ ] Inappropriate content filtering
  - [ ] Brand safety checks
  - [ ] Regional compliance rules

- [ ] Manual Review Queue
  - [ ] Web dashboard for trend approval
  - [ ] Human veto system
  - [ ] Batch approval interface

### 2.3 Allowlist/Denylist

- [ ] Keyword management
  - [ ] Blocked keywords (automatic rejection)
  - [ ] Allowed keywords (fast-track approval)
  - [ ] Regex pattern matching

- [ ] Creator management
  - [ ] Trusted creators list
  - [ ] Blocked creators list

- [ ] API endpoints
  - [ ] POST /lists/allow
  - [ ] POST /lists/deny
  - [ ] DELETE /lists/:type
  - [ ] GET /lists

### 2.4 Enhanced Scoring

- [ ] Multi-factor scoring algorithm
  - [ ] Recency boost (catch trends early)
  - [ ] Novelty detection (avoid oversaturated topics)
  - [ ] Platform fit scoring (Instagram vs TikTok style)
  - [ ] Historical performance data

- [ ] Trend lifecycle tracking
  - [ ] Growth phase detection
  - [ ] Peak identification
  - [ ] Decline prediction

**Deliverable:** Selected trends marked as `selected` status, ready for content generation.

---

## 📹 Phase 3: Content Generation (Q2 2026)

**Goal:** Automatically create viral short-form videos

### 3.1 Script Generation

- [ ] LLM-powered script writing
  - [ ] Hook generation (first 3 seconds)
  - [ ] Story structure
  - [ ] Call-to-action optimization
  - [ ] Platform-specific variations

- [ ] Caption & Hashtag Generation
  - [ ] Engaging captions
  - [ ] Optimal hashtag selection
  - [ ] Emoji insertion
  - [ ] Link shortening

### 3.2 Media Acquisition

- [ ] Pexels API integration (royalty-free video)
  - [ ] Vertical video search (9:16 aspect ratio)
  - [ ] Keyword-based B-roll selection
  - [ ] Quality filtering
  - [ ] Download and caching

- [ ] Alternative sources
  - [ ] Pixabay Videos
  - [ ] Mixkit
  - [ ] User-uploaded library

### 3.3 Video Composition

- [ ] ffmpeg pipeline
  - [ ] Text overlay with timing
  - [ ] Subtitle generation and rendering
  - [ ] Background video composition
  - [ ] Audio mixing
  - [ ] Export to 9:16 MP4

- [ ] Thumbnail generation
  - [ ] Key frame extraction
  - [ ] Text overlay
  - [ ] Brand watermark

### 3.4 Consider Daytona for Sandboxes

**Decision Point:** Evaluate if Daytona workspaces are needed for:
- Isolated video generation environments
- Parallel processing multiple videos
- Resource-intensive ffmpeg operations

**Alternative:** Run ffmpeg on main server if resources allow.

**Deliverable:** Generated MP4 videos with captions, ready for posting.

---

## 📱 Phase 4: Multi-Platform Posting (Q3 2026)

**Goal:** Automatically post content to social platforms

### 4.1 Instagram Posting

- [ ] Browser Use Cloud for posting
  - [ ] Login automation
  - [ ] Image/video upload
  - [ ] Caption and hashtag insertion
  - [ ] Story vs Reel selection
  - [ ] Post URL capture

- [ ] Rate limiting
  - [ ] Max posts per hour
  - [ ] Random delays between posts
  - [ ] Human-like behavior simulation

### 4.2 TikTok Posting

- [ ] Browser Use Cloud automation
  - [ ] Upload flow
  - [ ] Caption and sounds
  - [ ] Post scheduling

### 4.3 YouTube Shorts

- [ ] YouTube API integration
  - [ ] Upload via API
  - [ ] Title, description optimization
  - [ ] Shorts-specific formatting

### 4.4 X (Twitter)

- [ ] Video posting via API
  - [ ] 280 character optimization
  - [ ] Thread creation for longer content

### 4.5 Consider Daytona for Posting

**Decision Point:** Evaluate if Daytona workspaces are needed for:
- Isolated browser sessions per platform
- Parallel posting to multiple accounts
- CAPTCHA and verification handling

**Alternative:** Use Browser Use Cloud directly (currently using for discovery).

**Deliverable:** Posts live on platforms with captured URLs.

---

## 📊 Phase 5: Performance Tracking & Optimization (Q4 2026)

**Goal:** Monitor performance and double down on winners

### 5.1 Metrics Collection

- [ ] Platform API integrations
  - [ ] Instagram Insights
  - [ ] TikTok Analytics
  - [ ] YouTube Analytics
  - [ ] X (Twitter) Analytics

- [ ] Metrics storage
  - [ ] Views, likes, comments, shares
  - [ ] Watch time and completion rate
  - [ ] Click-through rate
  - [ ] Follower growth

### 5.2 Performance Analysis

- [ ] Trend performance scoring
  - [ ] Early indicators (first hour metrics)
  - [ ] Growth trajectory prediction
  - [ ] Viral coefficient calculation

- [ ] Content analysis
  - [ ] What hooks work best
  - [ ] Optimal video length
  - [ ] Best posting times
  - [ ] Hashtag performance

### 5.3 Automated Optimization

- [ ] Follow-up strategy
  - [ ] If positive signals → create more similar content
  - [ ] If negative → stop trend immediately
  - [ ] A/B test different approaches

- [ ] Budget allocation
  - [ ] Multi-armed bandit algorithm
  - [ ] Allocate resources to winners
  - [ ] Cut losers quickly

**Deliverable:** Self-optimizing system that learns what works.

---

## 💰 Phase 6: Monetization (2027)

**Goal:** Generate revenue from viral content

### 6.1 Affiliate Integration

- [ ] Link insertion in captions
  - [ ] Amazon Associates
  - [ ] Commission Junction
  - [ ] ShareASale

- [ ] Landing pages
  - [ ] `/in/:postId` redirect pages
  - [ ] Product recommendations
  - [ ] Conversion tracking

### 6.2 Sponsored Content

- [ ] Brand partnerships
  - [ ] Sponsored trend selection
  - [ ] Product placement
  - [ ] Sponsored captions

### 6.3 Paid Features

- [ ] API access tiers
  - [ ] Free tier: 100 requests/day
  - [ ] Pro tier: Unlimited + webhooks
  - [ ] Enterprise: Custom deployment

**Deliverable:** Revenue-generating viral content machine.

---

## 🎛️ Phase 7: Dashboard & Management (Ongoing)

**Goal:** User-friendly interface for monitoring and control

### 7.1 Web Dashboard

- [ ] Trend overview
  - [ ] Real-time trend feed
  - [ ] Status indicators
  - [ ] Performance metrics

- [ ] Content library
  - [ ] Generated videos
  - [ ] Post history
  - [ ] Analytics charts

- [ ] Control panel
  - [ ] Stop/start trends
  - [ ] Allowlist/denylist management
  - [ ] Settings configuration

### 7.2 Mobile App

- [ ] iOS/Android app
  - [ ] Push notifications for new trends
  - [ ] Quick approval/rejection
  - [ ] Performance dashboard

**Deliverable:** Beautiful, functional interface for managing the system.

---

## 🔧 Technical Debt & Improvements

### Short-term (Q1 2026)

- [ ] Add API authentication (Bearer tokens)
- [ ] Implement rate limiting
- [ ] Add request logging
- [ ] Set up monitoring alerts
- [ ] Database backups
- [ ] Error tracking (Sentry/Rollbar)

### Medium-term (Q2-Q3 2026)

- [ ] Migrate to PostgreSQL (from SQLite)
- [ ] Add Redis for caching
- [ ] Implement job queue (Bull/BullMQ)
- [ ] Add CI/CD pipeline
- [ ] Load testing and optimization
- [ ] Documentation site

### Long-term (2027)

- [ ] Multi-region deployment
- [ ] Kubernetes orchestration
- [ ] GraphQL API
- [ ] Real-time websocket updates
- [ ] Machine learning for trend prediction
- [ ] Custom LLM fine-tuning

---

## 🎯 Success Metrics

### Phase 1 (✅ Achieved)
- 10+ trends discovered per cycle
- <100ms API response time
- 99.9% uptime

### Phase 2 (Target)
- 90% trend classification accuracy
- <5% false positive safety flags
- <2 second LLM analysis time

### Phase 3 (Target)
- 100 videos generated per day
- <5 minute generation time per video
- 95% usable content (passes quality check)

### Phase 4 (Target)
- 50+ posts per day across platforms
- <1% post failures
- Zero account bans

### Phase 5 (Target)
- 5% of content goes viral (>1M views)
- 10x ROI on winning trends
- 80% accurate early performance prediction

### Phase 6 (Target)
- $10k+ monthly revenue
- 15% conversion rate on affiliate links
- 3+ brand partnerships

---

## 🚀 Quick Wins (Can be done anytime)

- [ ] Email notifications for high-scoring trends
- [ ] Slack/Discord webhook integration
- [ ] CSV export of trends
- [ ] Trend comparison tool
- [ ] Historical trend search
- [ ] API usage analytics
- [ ] Custom trend keywords (user-defined monitoring)

---

## Notes

**Philosophy:** Ship fast, iterate based on data, focus on what works.

**Current Focus:** Phase 1 complete. Moving to Phase 2 (Selection Engine) next.

**Timeline:** Flexible. Phases may overlap or be reordered based on learning and market needs.

**Team:** Solo developer currently. May expand in Phase 3+.
