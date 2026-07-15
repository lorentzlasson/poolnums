# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file [Roc](https://www.roc-lang.org/) web app that renders random pool balls as an HTML page. Built on the `basic-webserver` platform; persists selections to Postgres via `roc-pg`. Deployed on Render (https://poolnums.onrender.com/).

## Commands

The Nix dev shell (`flake.nix`, auto-loaded via direnv) provides `roc` and `pgcli`.

- `roc dev main.roc` — build and run the server locally (defaults to `127.0.0.1:8000`)
- `roc build main.roc` — produce the `main` binary
- `roc format main.roc` — format
- `roc check main.roc` — typecheck without building
- `docker compose up` — run the app + a Postgres db together
- `./deploy.sh` — build image, push to `rymdkraftverk/poolnums`, trigger Render deploy (needs `.env` with `DEPLOY_URL`)

There are no tests.

Server env vars (from `basic-webserver`): `ROC_BASIC_WEBSERVER_HOST` (Dockerfile sets `0.0.0.0`), `ROC_BASIC_WEBSERVER_PORT` (default 8000).

## Architecture

Everything lives in `main.roc`. The `main = \req -> ...` request handler routes only `GET /`; anything else 404s.

Request flow (`generateBoolBalls`):
1. Seed `roc-random` from the current epoch millis.
2. `removeRandomFromList` works by *elimination*: it starts from all 15 ball numbers and randomly drops balls until `15 - targetCount` remain; `getSelected` then returns the dropped ones as the selection. Count comes from the `?balls=` query param (`defaultTargetCount = 3`).
3. `storeSelection` persists to Postgres — but **only when exactly 3 balls** were selected (the `Triplet` case); other counts render but are not stored.
4. Errors from the DB step are swallowed by `handlePgError`, so the page still renders even if Postgres is unreachable.

`allBalls` maps ball number → external image URL; `renderBall` looks up the image and emits an `<img>`.

### Data & Postgres

- `schema.sql` defines the single `selection` table (`time, a, b, c`).
- `dbConfig` is hardcoded to `localhost:5432` / user+db `postgres`. This works in production because the Docker image runs Postgres **inside the same container** as the app (see below). For local `roc dev`, you need Postgres listening on `localhost:5432` with the schema loaded (e.g. `docker compose up db`).

### Deployment packaging

The `Dockerfile` is a two-stage build: stage one compiles `main.roc` with the Roc nightly image; stage two is `postgres:15.5` with the compiled binary and `schema.sql` copied in. `docker-start.sh` boots Postgres in the background (via `docker-entrypoint.sh`) and then runs `./main` in the foreground — so one container serves both the DB and the web app. `schema.sql` is mounted as an init script, so the table is created on first boot.

Note `compose.yaml` instead runs a *separate* `db` service; the `poolnums` service's own bundled Postgres goes unused there since `dbConfig` still points at `localhost`.

## Conventions

- Platform/library versions are pinned by URL+hash in the `app [main] { ... }` header of `main.roc`. Bumping a dependency means changing that hash.
- `crash "should never happen"` is used at spots the surrounding logic proves unreachable — keep those invariants intact when editing.
