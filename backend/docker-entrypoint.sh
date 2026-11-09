#!/bin/sh
set -eu

if [ "${DATABASE_AUTO_PUSH:-false}" = "true" ]; then
  echo "Applying Prisma schema for the local Docker environment..."
  npx prisma db push --skip-generate
fi

exec node dist/main.js
