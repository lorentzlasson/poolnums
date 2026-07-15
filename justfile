port := env_var_or_default("PORT", "8000")

default:
    @just --list

dev: db-up
    until docker compose exec -T db pg_isready --quiet; do sleep 1; done
    ROC_BASIC_WEBSERVER_PORT={{ port }} roc dev main.roc --linker legacy

check:
    roc check main.roc

fmt:
    roc format main.roc

build:
    roc build main.roc --linker legacy

db-up:
    docker compose up --detach db

db:
    pgcli postgres://postgres@localhost:5432/postgres

status:
    #!/usr/bin/env bash
    if [ -n "$(docker compose ps --status running --quiet db)" ]; then
      echo "db:  up"
      echo "selections: $(docker compose exec -T db psql --username postgres --dbname postgres --tuples-only --no-align --command 'select count(*) from selection;' 2>/dev/null)"
    else
      echo "db:  down"
    fi
    code=$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 2 "http://127.0.0.1:{{ port }}/" 2>/dev/null)
    if [ "$code" = "200" ]; then echo "app: up on {{ port }}"; else echo "app: down on {{ port }}"; fi

docker-up:
    docker compose up --build

down:
    docker compose down

deploy:
    ./deploy.sh
