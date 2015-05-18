#!/bin/bash

check-equals() {
  if [[ "$1" != "$2" ]]; then
    echo "$1 != $2" 1>&2
    exit 1
  fi
}
# acceptance test for the swarm -> flocker plugin example
vagrant up

vagrant ssh master -c "DOCKER_HOST=tcp://127.0.0.1:2375 \
docker run -d \
  -v flocker/data1:/data \
  -p 8080:80 \
  -e constraint:storage==disk \
  binocarlos/hello-increment"

counter=$(curl -sSL http://172.16.255.241:8080)


echo $counter