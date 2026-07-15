#!/usr/bin/env bash
set -euo pipefail

if ! process-compose process list --port "$PC_PORT_NUM" &>/dev/null; then
    echo "no services running"
    exit 1
fi

if [ -z "${1:-}" ]; then
    services=$(process-compose process list --port "$PC_PORT_NUM" | tr '\n' ',' | sed 's/,$//')
else
    services="$1"
fi

exec process-compose process logs --port "$PC_PORT_NUM" --follow "$services"
