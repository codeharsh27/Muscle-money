#!/usr/bin/env bash
echo "Running Prisma Migrations..."
npx prisma migrate deploy || echo "Warning: Migration failed, but continuing..."

echo "Starting NestJS Server..."
node dist/main.js
