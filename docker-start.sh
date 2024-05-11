export POSTGRES_HOST_AUTH_METHOD=trust

# imitate ENTRYPOINT and CMD from
# https://github.com/docker-library/postgres/blob/master/15/bookworm/Dockerfile
# and run in background
docker-entrypoint.sh postgres &

./main
