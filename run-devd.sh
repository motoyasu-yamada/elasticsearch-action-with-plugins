#!/bin/bash

if [ -z "$STACK_VERSION" ]; then
    STACK_VERSION="8.2.0"
fi

docker network rm elastic
docker build -t test .
docker run \
  --rm \
  --env "STACK_VERSION=$STACK_VERSION" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name es \
  test