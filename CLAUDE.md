# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file [Roc](https://www.roc-lang.org/) web app that renders random pool balls as an HTML page. Built on the `basic-webserver` platform; persists selections to Postgres via `roc-pg`. Deployed on Render (https://poolnums.onrender.com/).

## Commands

The Nix dev shell (`flake.nix`, auto-loaded via direnv) provides `roc` and `pgcli`. The compiler is pinned to Roc's `alpha4-rolling` release (the last Rust-compiler line; the newer Zig compiler has no webserver platform yet).

- `roc dev main.roc --linker legacy` — build and run the server locally (defaults to `127.0.0.1:8000`). The `--linker legacy` flag is required: alpha4's surgical linker fails on this platform.
- `roc build main.roc --linker legacy` — produce the `main` binary
- `roc check main.roc` — typecheck without building
- `roc format main.roc` — format
- `docker compose up` — run the app + a Postgres db together
- `./deploy.sh` — build image, push to `rymdkraftverk/poolnums`, trigger Render deploy (needs `.env` with `DEPLOY_URL`)

Postgres must be reachable at `localhost:5432` before the server starts — it connects once at boot (see below), so run `docker compose up db` first for local `roc dev`.

There are no tests.

Server env vars (from `basic-webserver`): `ROC_BASIC_WEBSERVER_HOST` (Dockerfile sets `0.0.0.0`), `ROC_BASIC_WEBSERVER_PORT` (default 8000).

## Architecture

Everything lives in `main.roc`, a `basic-webserver` app of the shape `app [Model, init!, respond!]`. `init!` opens the Postgres connection once and stores it in the `Model`; `respond!` handles requests and routes only `GET /`, 404ing everything else. Effects use the `!`-suffix convention (no `Task`); errors propagate with `?`.

Request flow (`generate_pool_balls!`):
1. Seed `roc-random` from the current epoch millis.
2. `remove_random_from_list` works by *elimination*: it starts from all 15 ball numbers and randomly drops balls until `15 - target_count` remain; `get_selected` then returns the dropped ones as the selection. Count comes from the `?balls=` query param (`default_target_count = 3`).
3. `store_selection!` persists to Postgres — but **only when exactly 3 balls** were selected (the `[a, b, c]` match); other counts render but are not stored.
4. A failed insert is caught and logged, so a request never 500s on a transient DB error. But the *initial* connection is in `init!`, so the server will not start at all if Postgres is unreachable at boot.

`all_balls` maps ball number → external image URL; `render_ball` looks up the image and emits an `<img>`.

### Data & Postgres

- `schema.sql` defines the single `selection` table (`time, a, b, c`).
- `db_config` is hardcoded to `localhost:5432` / user+db `postgres`. This works in production because the Docker image runs Postgres **inside the same container** as the app (see below). For local `roc dev`, you need Postgres listening on `localhost:5432` with the schema loaded (e.g. `docker compose up db`).

### Deployment packaging

The `Dockerfile` is a two-stage build: stage one is `debian:bookworm-slim` which downloads the pinned `alpha4-rolling` Roc release binary and runs `roc build /main.roc --linker legacy`; stage two is `postgres:15.5` with the compiled binary and `schema.sql` copied in. Bookworm is used as the builder base so the binary's glibc matches the `postgres:15.5` runtime. `docker-start.sh` boots Postgres in the background (via `docker-entrypoint.sh`), waits for `pg_isready` (the app connects at startup, so this avoids a boot race), then runs `./main` in the foreground — so one container serves both the DB and the web app. `schema.sql` is mounted as an init script, so the table is created on first boot.

Note `compose.yaml` instead runs a *separate* `db` service; the `poolnums` service's own bundled Postgres goes unused there since `db_config` still points at `localhost`.

## Conventions

- Platform/library versions are pinned by URL+hash in the `app [...] { ... }` header of `main.roc`; the compiler is pinned in `flake.nix` (dev shell) and `Dockerfile` (release build). Bumping any of them means keeping all these pins in sync with a compatible set.
- `crash("should never happen")` is used at spots the surrounding logic proves unreachable — keep those invariants intact when editing.
