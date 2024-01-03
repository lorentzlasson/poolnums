#!/bin/bash
source .env

set -e

ls ../basic-webserver/platform/main.roc

docker login
(
  cd ..
  docker build --file poolnums/Dockerfile --tag rymdkraftverk/poolnums:latest .
)
docker push rymdkraftverk/poolnums:latest
curl -X POST $DEPLOY_URL
