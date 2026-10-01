#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

ORG=rymdkraftverk
PROJECT=poolnums
APP=poolnums
URL=https://poolnums.fogpipe.cloud

# The registry path spells the org as its short id, not its name. The token
# broker grants push on `rkv/poolnums/poolnums` and grants an empty scope on
# `rymdkraftverk/poolnums/poolnums`, which docker reports as `unauthorized` —
# indistinguishable from a bad credential. Pulls are unaffected either way,
# since the kubelet pulls with an operator credential that resolves nothing.
IMAGE="registry.cloud.fogpipe.com/rkv/${PROJECT}/${APP}"

fp() { fpcloud "$@" --org "$ORG" --project "$PROJECT"; }

if ! fp auth status >/dev/null 2>&1; then
  echo "not authenticated — run: fpcloud login" >&2
  exit 1
fi

sha=$(git rev-parse --short HEAD)
tag="${IMAGE}:${sha}"

echo "==> building ${tag}"
fp registry login
docker build --platform linux/amd64 --file Dockerfile --tag "$tag" .

echo "==> pushing"
docker push "$tag"

echo "==> deploying"
fp app deploy "$APP" --image "$tag" --release "$sha"

# A green deploy is not proof the new revision serves traffic, so confirm the
# image the app reports back is the one just pushed.
echo "==> verifying"
for attempt in $(seq 1 30); do
  live=$(fp app version "$APP" --output json | sed -n '/^{/,$p' | jq --raw-output '.image')
  if [ "$live" = "$tag" ]; then
    code=$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 10 "$URL/")
    if [ "$code" = 200 ]; then
      echo "    live: ${URL} @ ${sha}"
      exit 0
    fi
  fi
  if [ "$attempt" = 30 ]; then
    echo "error: ${tag} not serving (image: ${live:-none})" >&2
    exit 1
  fi
  sleep 5
done
