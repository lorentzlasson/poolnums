# can't use alpine - not sure why
FROM debian

ADD main /
ADD entrypoint.sh /

ENV ROC_BASIC_WEBSERVER_HOST=0.0.0.0

RUN chmod +x /entrypoint.sh

CMD ./entrypoint.sh
