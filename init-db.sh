#!/bin/bash
set -e

echo "⏳ Waiting for PostgreSQL to be ready..."
until PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d postgres -c '\q'; do
  >&2 echo "PostgreSQL is not ready, sleeping..."
  sleep 2
done

echo "🔍 Checking if database metabase_config exists..."
if ! PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -lqt | cut -d \| -f 1 | grep -qw metabase_config; then
  echo "🔄 Creating database metabase_config..."
  PGPASSWORD=$PGPASSWORD createdb -h "$PGHOST" -U "$PGUSER" metabase_config
  PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE metabase_config TO $PGUSER;"
  echo "✅ Database metabase_config created successfully"
else
  echo "ℹ️ Database metabase_config already exists, skipping creation"
fi
