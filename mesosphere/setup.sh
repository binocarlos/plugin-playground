#!/bin/bash

[ `id -u` = 0 ] || {
  echo "setup.sh must be run as 'root'" >&2
  exit 1
}

setup-minion() {
  docker pull binocarlos/hello-increment:latest
  bash /vagrant/mesosphere-download.sh
  bash /vagrant/mesosphere-install.sh slave
}

setup-master() {
  bash /vagrant/mesosphere-download.sh
  bash /vagrant/mesosphere-install.sh master
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