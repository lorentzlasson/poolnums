FROM debian:bookworm-slim AS builder

RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl --fail --silent --show-error --location \
    "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-09-29-7f11a82/roc_nightly-linux_x86_64-2026-09-29-7f11a82.tar.gz" \
    --output /roc.tar.gz \
    && echo "3f3911f8386cb34561f9fc93a1d04bf1c1a8a0f4c4c9785d9f0291dc8d10fd15  /roc.tar.gz" | sha256sum --check --strict \
    && mkdir --parents /opt/roc \
    && tar --extract --gzip --file /roc.tar.gz --directory /opt/roc --strip-components=1 \
    && ln --symbolic /opt/roc/roc /usr/local/bin/roc

WORKDIR /app

COPY ./main.roc ./

# exit code 2 means the build succeeded with warnings, which the 0.16.0
# platform package emits under current nightlies
RUN roc build main.roc || [ $? -eq 2 ]

# the binary is statically linked against musl, so it needs no runtime image
FROM scratch

COPY --from=builder /app/main /main

ENV HOST=0.0.0.0

USER 65534:65534

CMD ["/main"]
