#!/bin/sh
# switch to local platform source on main.roc:3
# docker login
docker build --tag rymdkraftverk/poolnums:latest .
docker push rymdkraftverk/poolnums:latest
