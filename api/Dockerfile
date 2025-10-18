FROM node:20-alpine

WORKDIR /app

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm install

# Generate Prisma client
RUN npx prisma generate

# Copy source code and startup script
COPY src ./src
COPY start.sh ./

# Create data directory for SQLite
RUN mkdir -p /app/data

# Make startup script executable
RUN chmod +x /app/start.sh

EXPOSE 3000

CMD ["/app/start.sh"]
