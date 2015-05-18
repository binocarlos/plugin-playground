#!/usr/bin/env bash

[ `id -u` = 0 ] || {
  echo "setup.sh must be run as 'root'" >&2
  exit 1
}

if [[ ! -f "/etc/flocker/my_address" ]]; then
  echo "file /etc/flocker/my_address does not exist" >&2
  exit 1
fi

if [[ ! -f "/etc/flocker/master_address" ]]; then
  echo "file /etc/flocker/master_address does not exist" >&2
  exit 1
fi

CONTROL_NODE=$(cat /etc/flocker/master_address)
MY_NETWORK_IDENTITY=$(cat /etc/flocker/my_address)

setup-ssh() {
  # make nodes trust eachother by using the same insecure key for root on both
  # nodes and adding the same to root's authorized_keys file.
  wget --quiet -O /root/.ssh/id_rsa https://raw.githubusercontent.com/binocarlos/generic-flocker-extension-demo/master/insecure_private_key
  wget --quiet -O /tmp/insecure_private_key.pub https://raw.githubusercontent.com/binocarlos/generic-flocker-extension-demo/master/insecure_private_key.pub
  chmod 600 /root/.ssh/id_rsa
  cat /tmp/insecure_private_key.pub >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  rm /tmp/insecure_private_key.pub
}

setup-zpool() {
  # re-taste the zpool if necessary
  sudo zpool import -d / flocker
}

setup-config() {
  mkdir -p /etc/flocker
  cat <<EOF > /etc/flocker/agent.yml
control-service: {hostname: '${CONTROL_NODE}', port: 4524}
version: 1
EOF
}

setup-control-service() {
  # setup flocker-control on master only
  FLOCKER_CONTROL_PORT=4523
  FLOCKER_CONTROL=`which flocker-control`
  cmd="$FLOCKER_CONTROL -p tcp:$FLOCKER_CONTROL_PORT"
  service="flocker-control"
  cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF
}

setup-zfs-agent() {
  # setup flocker-zfs-agent on both nodes
  FLOCKER_ZFS_AGENT=`which flocker-zfs-agent`
  cmd="$FLOCKER_ZFS_AGENT"
  service="flocker-zfs-agent"
  cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF
}

setup-container-agent() {
  # setup flocker-container-agent on both nodes
  FLOCKER_CONTAINER_AGENT=`which flocker-container-agent`
  cmd="$FLOCKER_CONTAINER_AGENT"
  service="flocker-container-agent"
  cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF
}

setup-flocker-plugin() {
  # variables for running the flocker plugin
  PF_VERSION="testing_combined_volume_plugin"
  MY_HOST_UUID=$(python -c "import json; print json.load(open('/etc/flocker/volume.json'))['uuid']")
  FLOCKER_CONTROL_SERVICE_BASE_URL=http://$CONTROL_NODE:4523/v1
  TWISTD=`which twistd`

  # checkout the correct flocker plugin branch
  cd /root && git clone https://github.com/clusterhq/powerstrip-flocker
  cd /root/powerstrip-flocker && git checkout $PF_VERSION

  # create a supervisor entry that will run the plugin
  cmd="cd /root/powerstrip-flocker && FLOCKER_CONTROL_SERVICE_BASE_URL=$FLOCKER_CONTROL_SERVICE_BASE_URL \
  MY_NETWORK_IDENTITY=$MY_NETWORK_IDENTITY \
  MY_HOST_UUID=$MY_HOST_UUID \
  $TWISTD -noy /root/powerstrip-flocker/powerstripflocker.tac"
  service="flocker-plugin"
  cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF
}

setup-docker() {
  # install the latest docker binary that understands plugins
  service docker stop
  wget --quiet -O /usr/bin/docker http://storage.googleapis.com/experiments-clusterhq/docker-volume-extensions/docker
  chmod a+x /usr/bin/docker
  service docker start

  mkdir -p /usr/share/docker/plugins  
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
  setup-docker
  supervisorctl update
  setup-flocker-plugin
  supervisorctl update
}

setup-master() {
  setup-common
  setup-control-service
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