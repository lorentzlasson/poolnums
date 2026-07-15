#!/usr/bin/env bash
set -euo pipefail

if [ -d "$PGDATA" ]; then
    echo "Database already initialized at $PGDATA"
    exit 0
fi

initdb --username=postgres --auth=trust

cat >> "$PGDATA/postgresql.conf" <<EOF
listen_addresses = 'localhost'
port = $DB_PORT
unix_socket_directories = '/tmp'
log_statement = 'all'
EOF

pg_ctl --log="$PGDATA/postgres.log" start

until pg_isready --dbname="$DATABASE_URL"; do
    sleep 0.5
done

psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --file=schema.sql

pg_ctl stop

echo "Database initialized successfully"
