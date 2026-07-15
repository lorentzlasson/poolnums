# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file [Roc](https://www.roc-lang.org/) web app that renders random pool balls as an HTML page. Built on the `basic-webserver` platform; persists selections to Postgres via `roc-pg`. Deployed on Render (https://poolnums.onrender.com/).

## Commands

The Nix dev shell (`flake.nix`, auto-loaded via direnv) provides `roc`, `pgcli`, `postgresql`, `process-compose`, and `just`. The compiler is pinned to Roc's `alpha4-rolling` release (the last Rust-compiler line; the newer Zig compiler has no webserver platform yet). Local dev is Docker-free: Postgres runs via `pg_ctl` and the server via `process-compose`. Ports come from `.envrc` (non-standard: app `8420`, db `5440`).

Common tasks go through the `justfile` (`just` to list):

- `just start` — start Postgres (`db-start`) then run the server under `process-compose`
- `just dev` — start Postgres then run `roc dev` in the foreground
- `just db-start` / `just db-stop` / `just db-destroy` — manage the local Postgres cluster (`.postgres-data`)
- `just db` — `pgcli` shell into the local database
- `just status` — show db / app / stored-selection-count
- `just check` / `just fmt` / `just build` — `roc check` / `roc format` / `roc build --linker legacy`
- `just deploy` — build the image, push to `rymdkraftverk/poolnums`, trigger the Render deploy (needs `.env` with `DEPLOY_URL`)

`--linker legacy` is required everywhere `roc build`/`roc dev` runs: alpha4's surgical linker fails on this platform. There are no tests.

The server connects to Postgres at boot, so the db must be up first (`just start`/`just dev` handle the ordering). Server env vars (from `basic-webserver`): `ROC_BASIC_WEBSERVER_HOST` (Dockerfile sets `0.0.0.0`), `ROC_BASIC_WEBSERVER_PORT` (`.envrc` sets it to `$PORT`).

## Architecture

Everything lives in `main.roc`, a `basic-webserver` app of the shape `app [Model, init!, respond!]`. `init!` opens the Postgres connection once and stores it in the `Model`; `respond!` handles requests and routes only `GET /`, 404ing everything else. Effects use the `!`-suffix convention (no `Task`); errors propagate with `?`.

Request flow (`generate_pool_balls!`):
1. Seed `roc-random` from the current epoch millis.
2. `remove_random_from_list` works by *elimination*: it starts from all 15 ball numbers and randomly drops balls until `15 - target_count` remain; `get_selected` then returns the dropped ones as the selection. Count comes from the `?balls=` query param (`default_target_count = 3`).
3. `store_selection!` persists to Postgres — but **only when exactly 3 balls** were selected (the `[a, b, c]` match); other counts render but are not stored.
4. A failed insert is caught and logged, so a request never 500s on a transient DB error. But the *initial* connection is in `init!`, so the server will not start at all if Postgres is unreachable at boot.

`all_balls` maps ball number → external image URL; `render_ball` looks up the image and emits an `<img>`.

### Data & Postgres

- `schema.sql` defines the single `selection` table (`time, a, b, c`). It is loaded by `scripts/init-postgres.sh` locally, and mounted as a Docker init script in production.
- `init!` reads the connection from the standard libpq env vars `PGHOST` / `PGPORT` / `PGUSER` / `PGDATABASE`, each defaulting to `localhost` / `5432` / `postgres` / `postgres`. Locally, `.envrc` points `PGPORT` at `5440`; in production nothing is set, so the defaults hit the Postgres running **inside the same container** (see below).

### Deployment packaging

Deployment still uses Docker (only local dev is Docker-free). The `Dockerfile` is a two-stage build: stage one is `debian:bookworm-slim` which downloads the pinned `alpha4-rolling` Roc release binary and runs `roc build /main.roc --linker legacy`; stage two is `postgres:15.5` with the compiled binary and `schema.sql` copied in. Bookworm is used as the builder base so the binary's glibc matches the `postgres:15.5` runtime. `docker-start.sh` boots Postgres in the background (via `docker-entrypoint.sh`), waits for `pg_isready` (the app connects at startup, so this avoids a boot race), then runs `./main` in the foreground — so one container serves both the DB and the web app. `schema.sql` is mounted as an init script, so the table is created on first boot.

## Conventions

- Platform/library versions are pinned by URL+hash in the `app [...] { ... }` header of `main.roc`; the compiler is pinned in `flake.nix` (dev shell) and `Dockerfile` (release build). Bumping any of them means keeping all these pins in sync with a compatible set.
- `crash("should never happen")` is used at spots the surrounding logic proves unreachable — keep those invariants intact when editing.
