# debian based
FROM roclang/nightly-ubuntu-latest as builder

COPY ./main.roc /main.roc

RUN roc build /main.roc; exit 0 # ignore faulty compile warnings

FROM postgres:15.5 as run

COPY --from=builder /main /

ENV ROC_BASIC_WEBSERVER_HOST=0.0.0.0

COPY ./schema.sql /docker-entrypoint-initdb.d/1-schema.sql
COPY ./docker-start.sh /

CMD ./docker-start.sh
