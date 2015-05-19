#!/bin/bash

unixsecs=$(date +%s)

check-equals() {
  if [[ "$1" != "$2" ]]; then
    echo "$1 != $2" 1>&2
    exit 1
  fi
}

# block until the app container is running
wait-for-app-running() {
  while [[ ! `vagrant ssh master -c "kubectl get pods | grep name=app | grep Running"` ]];
  do
    echo "wait for container to be Running" && sleep 5
  done
  echo "Sleeping for 10 secs for network"
  sleep 10
}

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
vagrant ssh master -c "kubectl get rc app -o yaml | sed 's/spinning/ssd/' | kubectl update -f -"

# remove the pod from node1
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
vagrant ssh master -c "kubectl delete rc -l name=app"
vagrant ssh master -c "kubectl delete pod -l name=app"
vagrant ssh master -c "kubectl delete service -l name=app"

echo
echo "all tests passed"
exit 0