#!/bin/bash

[ `id -u` = 0 ] || {
  echo "setup.sh must be run as 'root'" >&2
  exit 1
}

setup-minion() {
  docker pull binocarlos/hello-increment:latest
  bash /vagrant/setup-k8s.sh slave
}

setup-master() {
  bash /vagrant/setup-k8s.sh master
  chmod a+rx /usr/bin/kubectl

  # wait for the nodes to be up and then label them
  local node1=`kubectl get nodes | grep democluster-node1`
  local node2=`kubectl get nodes | grep democluster-node2`

  while [[ -z "$node1" ]]; do
    node1=`kubectl get nodes | grep democluster-node1`
    sleep 1
  done

  while [[ -z "$node2" ]]; do
    node2=`kubectl get nodes | grep democluster-node2`
    sleep 1
  done

  sleep 5

  kubectl label --overwrite nodes democluster-node1 disktype=spinning
  kubectl label --overwrite nodes democluster-node2 disktype=ssd
}

usage() {
cat <<EOF
Usage:
setup.sh master
setup.sh minion
setup.sh help
EOF
  exit 1
}

main() {
  case "$1" in
  master)             shift; setup-master $@;;
  minion)             shift; setup-minion $@;;
  *)                  usage $@;;
  esac
}

main "$@"