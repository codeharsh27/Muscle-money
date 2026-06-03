#!/usr/bin/env bash
echo "Running Prisma Migrations..."
npx prisma migrate deploy

echo "Starting NestJS Server..."
node dist/main.js
