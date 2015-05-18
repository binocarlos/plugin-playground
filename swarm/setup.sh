#!/bin/bash

[ `id -u` = 0 ] || {
  echo "setup.sh must be run as 'root'" >&2
  exit 1
}

setup-common() {
  setup-ssh
  setup-zpool
  setup-config
}

setup-minion() {
  setup-common
  setup-zfs-agent
  setup-container-agent
  supervisorctl update
  sleep 5
  setup-flocker-plugin
}

setup-master() {
  setup-common
  setup-control-service
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




docker pull swarm

DOCKER_HOST=unix:///var/run/docker.real.sock docker pull binocarlos/multi-http-demo-api
DOCKER_HOST=unix:///var/run/docker.real.sock docker pull binocarlos/multi-http-demo-server