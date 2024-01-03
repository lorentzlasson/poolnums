# debian based
FROM rust as builder

RUN curl -L -o roc.tar.gz https://github.com/roc-lang/roc/releases/download/nightly/roc_nightly-linux_x86_64-latest.tar.gz
RUN tar -xvz -f roc.tar.gz --directory /usr/bin --strip-components=1 # will be a mess /usr/bin but 🤷

COPY ./poolnums/main.roc /poolnums/main.roc
COPY ./basic-webserver /basic-webserver

RUN roc build /poolnums/main.roc; exit 0 # ignore faulty compile warnings

FROM debian as run

COPY --from=builder /poolnums/main /

ENV ROC_BASIC_WEBSERVER_HOST=0.0.0.0

CMD ./main
