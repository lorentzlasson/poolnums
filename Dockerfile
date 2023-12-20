# can't use alpine - not sure why
from debian

add main /

env ROC_BASIC_WEBSERVER_HOST=0.0.0.0

cmd ./main
