#!/usr/bin/env bash
. .env

set -e

docker login
docker build --file Dockerfile --tag rymdkraftverk/poolnums:latest .
docker push rymdkraftverk/poolnums:latest
curl --request POST "$DEPLOY_URL"
