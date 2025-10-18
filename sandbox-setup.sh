#!/bin/bash
set -e

echo "========================================"
echo "AutoViral Sandbox Setup"
echo "========================================"

# Install Node.js 20.x
echo "\n[1/6] Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs
node --version
npm --version

# Install system dependencies
echo "\n[2/6] Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y ffmpeg jq git curl

# Clone repository
echo "\n[3/6] Cloning repository..."
rm -rf /workspace
git clone git@github.com:Hack-a-tons/AutoViral.git /workspace
cd /workspace

# Setup .env file
echo "\n[4/6] Setting up environment variables..."
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "Created .env from .env.example"
        echo "⚠️  Please edit .env with your actual API keys!"
    else
        echo "⚠️  No .env.example found. Please create .env manually."
    fi
fi

# Install Node dependencies
echo "\n[5/6] Installing Node.js dependencies..."
npm install

# Check if docker-compose is available
echo "\n[6/6] Checking Docker..."
if command -v docker &> /dev/null; then
    echo "✓ Docker is available"
else
    echo "⚠️  Docker not found - may need manual installation"
fi

echo "\n========================================"
echo "✓ Setup complete!"
echo "========================================"
echo "\nNext steps:"
echo "  1. Edit /workspace/.env with your API keys"
echo "  2. Start your application (e.g., npm run dev)"
echo "  3. Access via the sandbox URL"
