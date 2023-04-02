#!/bin/bash

set -euxo pipefail

if [[ -z $STACK_VERSION ]]; then
  echo -e "\033[31;1mERROR:\033[0m Required environment variable [STACK_VERSION] not set\033[0m"
  exit 1
fi

MAJOR_VERSION=`echo ${STACK_VERSION} | cut -c 1`

if [ "x${MAJOR_VERSION}" != 'x8' ]; then
  echo -e "\033[31;1mERROR:\033[0m STACK_VERSION should be 8.x.x\033[0m"
  exit 1
fi

set +e
if docker ps -a | grep -q "${container_name}"; then
  echo "Stopping and removing container ${container_name}..."
  docker stop es1
  docker rm es1
fi
if docker network ls | grep -q "${network_name}"; then
  echo "Removing network ${network_name}..."
  docker network rm es1
fi
docker network create elastic

docker run \
  --env "node.name=es1" \
  --env "cluster.name=docker-elasticsearch" \
  --env "cluster.initial_master_nodes=es1" \
  --env "discovery.seed_hosts=es1" \
  --env "cluster.routing.allocation.disk.threshold_enabled=false" \
  --env "bootstrap.memory_lock=true" \
  --env "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
  --env "xpack.security.enabled=false" \
  --env "xpack.security.http.ssl.enabled=false" \
  --env "xpack.license.self_generated.type=basic" \
  --env "action.destructive_requires_name=false" \
  --env "http.port=9200" \
  --ulimit nofile=65536:65536 \
  --ulimit memlock=-1:-1 \
  --publish "9200:9200" \
  --network=elastic \
  --name="es1" \
  --detach \
  -v /elasticsearch/plugins:/usr/share/elasticsearch/plugins \
  docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}

docker exec -u root es1 /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu analysis-kuromoji --batch

docker restart es1

set +e
sleep 10
docker run \
  --network elastic \
  --rm \
  appropriate/curl \
  --max-time 10 \
  --retry 5 \
  --retry-delay 5  \
  --retry-connrefused \
  --show-error \
  --silent \
  http://es1:9200/_cat/plugins

exit_status=$?
if [ $exit_status -eq 0 ]; then
  echo "Elasticsearch up and running"
else
  docker logs es1
  echo -e "\033[31;1mERROR:\033[0m The command failed with exit status: $exit_status\033[0m"
  exit 1
fi