# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file [Roc](https://www.roc-lang.org/) web app that renders random pool balls as an HTML page. Built on the `basic-webserver` platform. Stateless: nothing is persisted. Deployed on Fogpipe Cloud (https://poolnums.fogpipe.cloud/).

## Commands

The Nix dev shell (`flake.nix`, auto-loaded via direnv) provides `roc`, `process-compose`, `just`, `jq`, and the `fpcloud` CLI. The compiler is Roc's new Zig-based compiler, pinned to a nightly release; `flake.nix` packages the statically linked release binary. The server runs locally under `process-compose`, on port `8420` (from `.envrc`).

Common tasks go through the `justfile` (`just` to list):

- `just start` — bring the server up under `process-compose` (detached), then follow its logs
- `just stop` — stop the `process-compose` services
- `just status` / `just log [service]` — process-compose status / follow logs
- `just check` / `just fmt` / `just build` — `roc check` / `roc fmt` / `roc build`
- `just deploy` — build the image, push it to the Fogpipe registry and roll out the new revision (needs `fpcloud login` once)

`roc build` exits `2` when it succeeds with warnings. The pinned platform release emits such warnings under current nightlies, so build steps treat `2` as success. There are no tests.

`init!` reads the listen address from `HOST` (default `127.0.0.1`) and `PORT` (default `8000`). The Dockerfile sets `HOST=0.0.0.0`.

## Architecture

Everything lives in `main.roc`, a `basic-webserver` app of the shape `app [Context, program]` with `program = { init!, respond!, shutdown! }`. `init!` builds the `Server.Config`; `respond!` routes only `GET /`, 404ing everything else. Effects use the `!`-suffix convention; errors propagate with `?`.

Request flow (`generate_pool_balls!`):
1. Seed `roc-random` from the current sub-second nanoseconds.
2. `remove_random_from_list` works by *elimination*: it starts from all 15 balls and randomly drops balls until `15 - target_count` remain; `get_selected` then returns the dropped ones as the selection. Count comes from the `?balls=` query param (`default_target_count = 3`).

`all_balls` pairs each ball number with an external image URL; `render_ball` emits an `<img>` for it via the platform's `Html` module.

### Deployment packaging

The `Dockerfile` is a two-stage build: stage one downloads the pinned nightly Roc release binary and runs `roc build`; the result is a statically linked musl binary, so stage two is `scratch` with just that binary, run as an unprivileged uid.

### Fogpipe Cloud

The app runs as the `poolnums` app in the `poolnums` project of the `rymdkraftverk` org, on port `8000`, health-checked on `/` (the only route it serves). `deploy.sh` builds the image, pushes it to `registry.cloud.fogpipe.com/rkv/poolnums/poolnums` — the org spelled as its short id, which is the only path the registry's token broker grants push on; the `rymdkraftverk/...` spelling the app's stored image uses is pullable but not pushable — tagged with the short commit sha, rolls it out with `fpcloud app deploy` and then waits until the app reports that image and the site answers 200. Auth is whatever `fpcloud login` left behind — the script refuses to run unauthenticated rather than half-deploying.

## Conventions

- Platform/package versions are pinned by URL+hash in the `app [...] { ... }` header of `main.roc`. The compiler nightly is pinned in three places that must agree: the header's `roc:` field (the compiler warns on mismatch; `roc fmt` rewrites it), `rocVersion` + per-arch hashes in `flake.nix`, and the tarball URL + sha256 in `Dockerfile`. Platform releases target specific nightlies, so bump the compiler and platform together and run the app before committing — nightlies regularly segfault.
- `crash "should never happen"` is used at spots the surrounding logic proves unreachable — keep those invariants intact when editing.
