docker run \
  -it \
  --rm \
  -p 3000:3000 \
  --add-host=host.docker.internal:host-gateway \
  werftest $*
