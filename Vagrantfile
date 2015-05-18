# -*- mode: ruby -*-
# vi: set ft=ruby sw=2 :

# This requires Vagrant 1.6.2 or newer (earlier versions can't reliably
# configure the Fedora 20 network stack).
Vagrant.require_version ">= 1.6.2"

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "lmarsden/flocker-tutorial"

  begin
    config.vm.box_version = "= " + ENV.fetch('FLOCKER_BOX_VERSION')
  rescue KeyError
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  # XXX NB: the "0.4.0" version of this box is actually flocker@master
  # 2015-05-13, I kept it named "0.4.0" for convenience with respect to not
  # needing to modify how flocker's acceptance test runner identifies version
  # numbers.

$node1 = <<NODE1
mkdir -p /etc/flocker
echo 172.16.255.240 > /etc/flocker/nodeip.txt
NODE1

$node2 = <<NODE2
mkdir -p /etc/flocker
echo 172.16.255.241 > /etc/flocker/nodeip.txt
NODE2

$master = <<MASTER
# setup flocker-control on master only
FLOCKER_CONTROL_PORT=4523
FLOCKER_CONTROL=`which flocker-control`
cmd="$FLOCKER_CONTROL -p tcp:$FLOCKER_CONTROL_PORT"
service="flocker-control"
cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF
supervisorctl update
MASTER


$common = <<COMMON
CONTROL_NODE=172.16.255.240
mkdir -p /etc/flocker
cat <<EOF > /etc/flocker/agent.yml
control-service: {hostname: '${CONTROL_NODE}', port: 4524}
version: 1
EOF
# make nodes trust eachother by using the same insecure key for root on both
# nodes and adding the same to root's authorized_keys file.
cp /vagrant/insecure_private_key /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
cat /vagrant/insecure_private_key.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
# re-taste the zpool if necessary
sudo zpool import -d / flocker
# setup flocker-zfs-agent on both nodes
FLOCKER_ZFS_AGENT=`which flocker-zfs-agent`
cmd="$FLOCKER_ZFS_AGENT"
service="flocker-zfs-agent"
cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF
# setup flocker-container-agent on both nodes
FLOCKER_CONTAINER_AGENT=`which flocker-container-agent`
cmd="$FLOCKER_CONTAINER_AGENT"
service="flocker-container-agent"
cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF

# we need to kick off the flocker agents now so that /etc/flocker/volume.json exists
supervisorctl update

sleep 5

# variables for running the flocker plugin
PF_VERSION="testing_combined_volume_plugin"
MY_HOST_UUID=$(python -c "import json; print json.load(open('/etc/flocker/volume.json'))['uuid']")
MY_NETWORK_IDENTITY=$(cat /etc/flocker/nodeip.txt)
FLOCKER_CONTROL_SERVICE_BASE_URL=http://$CONTROL_NODE:4523/v1
TWISTD=`which twistd`
PLUGINROOT=/root/powerstrip-flocker

# checkout the correct flocker plugin branch
cd /root && git clone https://github.com/clusterhq/powerstrip-flocker
cd /root/powerstrip-flocker && git checkout $PF_VERSION

# create a bash script that will start the plugin
cat << EOF > /root/run-flocker-plugin.sh
#!/usr/bin/env bash
cd /root/powerstrip-flocker && \
FLOCKER_CONTROL_SERVICE_BASE_URL=$FLOCKER_CONTROL_SERVICE_BASE_URL \
MY_NETWORK_IDENTITY=$MY_NETWORK_IDENTITY \
MY_HOST_UUID=$MY_HOST_UUID \
$TWISTD -noy /root/powerstrip-flocker/powerstripflocker.tac
EOF

# create a supervisor entry that will run the bash script
BASH=`which bash`
cmd="$BASH /root/run-flocker-plugin.sh"
service="flocker-plugin"
cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=$cmd
EOF

# install the latest docker binary that understands plugins
service docker stop
wget --quiet -O /usr/bin/docker http://storage.googleapis.com/experiments-clusterhq/docker-volume-extensions/docker
chmod a+x /usr/bin/docker
service docker start

mkdir -p /usr/share/docker/plugins

supervisorctl update
COMMON

  config.vm.define "node1" do |node1|
    node1.vm.network :private_network, :ip => "172.16.255.240"
    node1.vm.hostname = "node1"
    node1.vm.provision "shell", inline: $node1 + $master + $common
  end

  config.vm.define "node2" do |node2|
    node2.vm.network :private_network, :ip => "172.16.255.241"
    node2.vm.hostname = "node2"
    node2.vm.provision "shell", inline: $node2 + $common
  end

  config.vm.provision "file", source: "~/.ssh/id_rsa_flocker.pub", destination: "/tmp/id_rsa_flocker.pub"
  config.vm.provision "shell", inline: "cp /tmp/id_rsa_flocker.pub /root/.ssh/authorized_keys", privileged: true
  config.vm.provision "shell", inline: "chown root /root/.ssh/authorized_keys", privileged: true
  config.vm.provision "shell", inline: "chmod 0600 /root/.ssh/authorized_keys", privileged: true

end