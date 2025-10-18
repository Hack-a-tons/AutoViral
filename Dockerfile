# AutoViral Dockerfile for Daytona Sandbox
FROM mcr.microsoft.com/playwright:v1.47.2-jammy

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install additional tools
RUN apt-get update && apt-get install -y \
    ffmpeg \
    jq \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Set environment variables
ENV NODE_ENV=development \
    TZ=UTC \
    DISPLAY=:99 \
    PUPPETEER_DISABLE_HEADLESS_WARNING=true

# Expose ports
EXPOSE 3000 3001

# Create data directories
RUN mkdir -p /workspace/data /workspace/media /workspace/tmp

# Default command
CMD ["/bin/bash"]
