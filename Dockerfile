# can't use alpine - not sure why
from debian

add main /
add entrypoint.sh /

env ROC_BASIC_WEBSERVER_HOST=0.0.0.0

run chmod +x /entrypoint.sh

cmd ./entrypoint.sh
