# generic-flocker-extension-demo

A base installation of the Flocker extension for Docker.

## notes

 * [here](https://github.com/ClusterHQ/powerstrip-flocker/blob/testing_combined_volume_plugin/powerstripflocker/test/test_acceptance.py#L242) is a link to the plugin
 * [here](https://github.com/ClusterHQ/powerstrip-flocker/blob/testing_combined_volume_plugin/extra-vagrant-acceptance-targets/ubuntu-14.04/Vagrantfile) is a link to the vagrant setup for a Flocker cluster
 * [here](http://storage.googleapis.com/experiments-clusterhq/docker-volume-extensions/docker) is a link to the latest docker binary that is compiled to understand volume extensions

## setup

Steps to get this running:

 * get the Vagrant cluster up and running
 * download the latest docker binary and install it
 * install the Flocker plugin on each vagrant VM