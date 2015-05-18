#!/bin/bash

[ `id -u` = 0 ] || {
  echo "setup.sh must be run as 'root'" >&2
  exit 1
}

setup-common() {
  
}

setup-minion() {
  docker pull binocarlos/hello-increment:latest
}

setup-master() {
  docker pull swarm:latest

  DOCKER=`which docker`
  FLOCKER_CONTAINER_AGENT=`which flocker-container-agent`
  cmd="$FLOCKER_CONTAINER_AGENT"
  service="flocker-container-agent"
  cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF
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