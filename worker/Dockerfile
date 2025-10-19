FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY src ./src

# Create data directory for tracking
RUN mkdir -p /app/data

EXPOSE 3001

CMD ["npm", "start"]
