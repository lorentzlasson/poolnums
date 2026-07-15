#!/usr/bin/env bash
set -euo pipefail

if ! process-compose process list --port "$PC_PORT_NUM" &>/dev/null; then
    process-compose up --detached --disable-dotenv --port "$PC_PORT_NUM"
fi
