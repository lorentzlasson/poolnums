# bookworm base so the built binary's glibc matches the postgres:15.5 runtime
FROM debian:bookworm-slim as builder

RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN curl --fail --silent --show-error --location \
    "https://github.com/roc-lang/roc/releases/download/alpha4-rolling/roc-linux_x86_64-alpha4-rolling.tar.gz" \
    --output /roc.tar.gz \
    && echo "96e8be05e6f7176433ada74532ff36a62b8dc44c5247a82cdf919f2dadc5178b  /roc.tar.gz" | sha256sum --check --strict \
    && mkdir --parents /opt/roc \
    && tar --extract --gzip --file /roc.tar.gz --directory /opt/roc --strip-components=1 \
    && ln --symbolic /opt/roc/roc /usr/local/bin/roc

COPY ./main.roc /main.roc

RUN roc build /main.roc --linker legacy

FROM postgres:15.5 as run

COPY --from=builder /main /

ENV ROC_BASIC_WEBSERVER_HOST=0.0.0.0

COPY ./schema.sql /docker-entrypoint-initdb.d/1-schema.sql
COPY ./docker-start.sh /

USER postgres

CMD ./docker-start.sh
