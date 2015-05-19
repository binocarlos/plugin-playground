#!/bin/bash

unixsecs=$(date +%s)

check-equals() {
  if [[ "$1" != "$2" ]]; then
    echo "$1 != $2" 1>&2
    exit 1
  fi
}

# continue to loop over is-mesos-task-running until it is ready
wait-for-mesos-task() {
  local running=$(is-mesos-task-running $1)
  while [[ "$running" == "null" ]]
  do
    echo "wait for mesos task $1" && sleep 1    
    running=$(is-mesos-task-running $1)
  done
  echo "mesos task $1 is running"
  sleep 5
}

# told which node and which container - this will ssh to the node and
# run docker ps with a 'running' filter and grep the container name
is-docker-container-running() {
  local node=$1
  local container=$2
  vagrant ssh $node -c "sudo docker ps --filter \"status=running\" | grep $container"
}


# keep looping over `is-docker-container-running` until it is
wait-for-docker-container() {
  local node=$1
  local container=$2
  local running=$(is-docker-container-running $node $container)
  while [[ -z "$running" ]]
  do
    echo "waiting for docker container $container on $node"
    running=$(is-docker-container-running $node $container)
  done
  echo "docker container $container on node $node is running"
  sleep 1
}

cleanup() {
  echo "cleaning rcs"
  vagrant ssh master -c "kubectl delete rc -l name=app"
  echo "cleaning pods"
  vagrant ssh master -c "kubectl delete pod -l name=app"
  echo "cleaning services"
  vagrant ssh master -c "kubectl delete service -l name=app"
}

cleanup

# deploy the service and rc
echo "Adding app service definition"
vagrant ssh master -c "kubectl create -f /vagrant/example/service.json"
echo "listing services"
vagrant ssh master -c "kubectl get services"

echo "Deploying controller to node1"
# we replace the host path so we are guaranteed a fresh volume
vagrant ssh master -c "cat /vagrant/example/controller.json | sed 's/flocker\/testdata/flocker\/testdata$unixsecs/' | kubectl create -f -"
echo "waiting for pod to be deployed"
wait-for-app-running

echo "listing pods"
vagrant ssh master -c "kubectl get pods"

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
echo "Updating rc to target node2"
vagrant ssh master -c "kubectl get rc app -o yaml | sed 's/spinning/ssd/' | kubectl update -f -"

# remove the pod from node1
echo "Removing pod from node1"
vagrant ssh master -c "kubectl delete pod -l name=app"
wait-for-app-running

echo "listing pods"
vagrant ssh master -c "kubectl get pods"

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