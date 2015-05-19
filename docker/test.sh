#!/bin/bash

unixsecs=$(date +%s)

check-equals() {
  if [[ "$1" != "$2" ]]; then
    echo "$1 != $2" 1>&2
    exit 1
  fi
}

cleanup() {
  echo "cleaning containers from node1"
  vagrant ssh node1 -c "sudo docker ps -aq | xargs sudo docker rm -f"
  echo "cleaning containers from node2"
  vagrant ssh node2 -c "sudo docker ps -aq | xargs sudo docker rm -f"
}

run-app() {
  local node="$1"
  echo "Running app on $node"
  vagrant ssh $node -c "sudo docker run -d \
    --name flocker-test \
    -v flocker/data$unixsecs:/data \
    -p 8000:80 \
    -e FILE=/data/testdata.txt \
    binocarlos/hello-increment:latest"
}

cleanup

run-app node1

sleep 5

# increment and test the values
counter=$(curl -sSL http://172.16.255.241:8000)
echo "load first value (node1): $counter"
check-equals $counter 1
counter=$(curl -sSL http://172.16.255.241:8000)
echo "load second value (node1): $counter"
check-equals $counter 2
counter=$(curl -sSL http://172.16.255.241:8000)
echo "load third value (node1): $counter"
check-equals $counter 3

# update the rc to target node2
echo "Stopping app on node1"
vagrant ssh node1 -c "sudo docker rm -f flocker-test"

run-app node2

sleep 5

# increment and test the values
counter=$(curl -sSL http://172.16.255.242:8000)
echo "load fourth value (node2): $counter"
check-equals $counter 4
counter=$(curl -sSL http://172.16.255.242:8000)
echo "load fith value (node2): $counter"
check-equals $counter 5
counter=$(curl -sSL http://172.16.255.242:8000)
echo "load sixth value (node3): $counter"
check-equals $counter 6

# cleanup
cleanup

echo
echo "all tests passed"
exit 0