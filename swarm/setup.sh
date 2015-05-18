#!/bin/bash

[ `id -u` = 0 ] || {
  echo "setup.sh must be run as 'root'" >&2
  exit 1
}

setup-common() {
  
}

setup-minion() {
  docker pull binocarlos/hello-increment:latest
  # and get docker listening on tcp port
}

setup-master() {
  docker pull swarm:latest
  DOCKER=`which docker`
  SWARMIPS=`cat /etc/flocker/swarmips`
  cmd="$DOCKER run --name swarm \
    -p 2375:2375 \
    swarm manage -H 0.0.0.0:2375 $SWARMIPS"
  service="swarm"
  cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF

  supervisorctl update
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