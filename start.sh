#!/bin/bash

CONTAINER_FILE=Containerfile-bookworm
NAME=$(awk -v FS== '/org.opencontainers.image.ref.name/{print $2}' $CONTAINER_FILE)
VERSION=$(awk -v FS== '/org.opencontainers.image.version/{print $2}' $CONTAINER_FILE)

mkdir -p ./etc/tor ./var/log/tor ./var/lib/tor

podman run -it --rm \
  --name tor-container01 \
  -p 9050:9050 \
  -v $(pwd)/etc/tor:/etc/tor \
  -v $(pwd)/var/log/tor:/var/log/tor \
  -v $(pwd)/var/lib/tor:/var/lib/tor \
  localhost/$NAME:$VERSION
