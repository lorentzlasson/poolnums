default:
    @just --list

[private]
_ensure-services: db-start
    ./scripts/start-services.sh

start: _ensure-services
    ./scripts/log.sh

stop:
    process-compose down --port $PC_PORT_NUM 2>/dev/null || true

status:
    ./scripts/status.sh

log service="":
    ./scripts/log.sh {{ service }}

check:
    roc check main.roc

fmt:
    roc format main.roc

build:
    roc build main.roc --linker legacy

db:
    pgcli "$DATABASE_URL"

db-start:
    ./scripts/init-postgres.sh
    pg_ctl --log="$PGDATA/postgres.log" start || true

db-stop:
    pg_ctl stop || true

db-destroy:
    pg_ctl stop 2>/dev/null || true
    rm --recursive --force "$PGDATA"

deploy:
    ./deploy.sh
