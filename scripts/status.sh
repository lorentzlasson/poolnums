#!/usr/bin/env bash
set -euo pipefail

services=$(process-compose process list --port "$PC_PORT_NUM" --output json 2>/dev/null || echo "[]")

if [[ "$services" == "[]" ]]; then
    echo "✗ process-compose (:$PC_PORT_NUM)"
    exit 0
fi

echo "✓ process-compose (:$PC_PORT_NUM)"

if pg_isready --quiet --dbname="$DATABASE_URL" 2>/dev/null; then
    echo "✓ db (:$DB_PORT)"
else
    echo "✗ db (:$DB_PORT)"
fi

echo "$services" | jq --raw-output '.[] | .name + " " + .is_ready + " " + .status' | while read -r name ready status; do
    case "$name" in
        server) port="$PORT" ;;
        *) port="" ;;
    esac

    display=""
    if [[ -n "$port" ]]; then
        if [[ "$ready" == "Ready" ]]; then
            display=" http://localhost:$port"
        else
            display=" (:$port)"
        fi
    fi

    if [[ "$ready" == "Ready" ]]; then
        echo "✓ $name$display"
    elif [[ "$status" != "Error" && "$status" != "Terminated" ]]; then
        echo "⏳ $name$display"
    else
        echo "✗ $name$display"
    fi
done
