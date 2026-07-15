default:
    @just --list

dev: db-start
    roc dev main.roc --linker legacy

check:
    roc check main.roc

fmt:
    roc format main.roc

build:
    roc build main.roc --linker legacy

db-start:
    ./scripts/init-postgres.sh
    pg_ctl --log="$PGDATA/postgres.log" start || true

db-stop:
    pg_ctl stop || true

db-destroy:
    pg_ctl stop 2>/dev/null || true
    rm --recursive --force "$PGDATA"

db:
    pgcli "$DATABASE_URL"

start: db-start
    process-compose up --port $PC_PORT_NUM

stop:
    process-compose down --port $PC_PORT_NUM 2>/dev/null || true

status:
    #!/usr/bin/env bash
    if pg_ctl status >/dev/null 2>&1; then
      echo "db:  up on ${DB_PORT}"
      echo "selections: $(psql "$DATABASE_URL" --tuples-only --no-align --command 'select count(*) from selection;' 2>/dev/null)"
    else
      echo "db:  down"
    fi
    code=$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 2 "http://localhost:${PORT}/" 2>/dev/null)
    if [ "$code" = "200" ]; then echo "app: up on ${PORT}"; else echo "app: down on ${PORT}"; fi

deploy:
    ./deploy.sh
