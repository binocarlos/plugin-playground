#!/bin/bash

unixsecs=$(date +%s)

check-equals() {
  if [[ "$1" != "$2" ]]; then
    echo "$1 != $2" 1>&2
    exit 1
  fi
}

stop-test-container() {
  # remove the test container from node1
  vagrant ssh master -c "DOCKER_HOST=tcp://127.0.0.1:2375 docker rm -f flocker-test" > /dev/null
}

run-test-container() {
  vagrant ssh master -c "DOCKER_HOST=tcp://127.0.0.1:2375 \
docker run -d \
  --name flocker-test \
  -v flocker/data$unixsecs:/data \
  -p 8080:80 \
  -e constraint:storage==$1 \
  -e FILE=/data/testdata.txt \
  binocarlos/hello-increment"
}

list-containers() {
  vagrant ssh master -c "DOCKER_HOST=tcp://127.0.0.1:2375 docker ps"
}

stop-test-container
# start the test container on node1
echo "starting container on node1"
run-test-container disk
echo "listing containers on node1"
list-containers

sleep 5

# increment and test the values
counter=$(curl -sSL http://172.16.255.241:8080)
echo "load first value (node1): $counter"
check-equals $counter 1
counter=$(curl -sSL http://172.16.255.241:8080)
echo "load second value (node1): $counter"
check-equals $counter 2
counter=$(curl -sSL http://172.16.255.241:8080)
echo "load third value (node1): $counter"
check-equals $counter 3

# remove the test container from node1
echo "stopping container on node1"
stop-test-container

sleep 5

# run the test container on node2
echo "running container on node2"
run-test-container ssd
echo "listing containers on node2"
list-containers

sleep 5

# increment and test the values
counter=$(curl -sSL http://172.16.255.242:8080)
echo "load fourth value (node2): $counter"
check-equals $counter 4
counter=$(curl -sSL http://172.16.255.242:8080)
echo "load fith value (node2): $counter"
check-equals $counter 5
counter=$(curl -sSL http://172.16.255.242:8080)
echo "load sixth value (node3): $counter"
check-equals $counter 6

# remove the test container from node2
stop-test-container

echo
echo "all tests passed"
exit 0