# can't use alpine - not sure why
FROM debian

ADD main /

ENV ROC_BASIC_WEBSERVER_HOST=0.0.0.0

CMD ./main
