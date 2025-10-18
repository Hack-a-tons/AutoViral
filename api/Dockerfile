FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm install

# Generate Prisma client
RUN npx prisma generate

# Copy source code
COPY src ./src

# Create data directory for SQLite
RUN mkdir -p /app/data

EXPOSE 3000

CMD ["npm", "start"]
