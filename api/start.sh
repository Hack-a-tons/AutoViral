#!/bin/sh
set -e

echo "Initializing database..."
npx prisma db push --skip-generate

echo "Starting API server..."
npm start
