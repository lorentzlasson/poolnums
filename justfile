default:
    @just --list

start:
    ./scripts/start-services.sh
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

# exit code 2 means the build succeeded with warnings
build:
    roc build main.roc || [ $? -eq 2 ]

deploy:
    ./deploy.sh
