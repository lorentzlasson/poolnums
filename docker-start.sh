export POSTGRES_USER=rkv
export POSTGRES_PASSWORD=supersecret
export POSTGRES_HOST_AUTH_METHOD=password
export POSTGRES_DB=rkv

# imitate ENTRYPOINT and CMD from
# https://github.com/docker-library/postgres/blob/master/15/bookworm/Dockerfile
# and run in background
docker-entrypoint.sh postgres &

./main
