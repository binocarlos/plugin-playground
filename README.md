# generic-flocker-extension-demo

A base installation of the Flocker extension for Docker.

## notes

 * [here](https://github.com/ClusterHQ/powerstrip-flocker/blob/testing_combined_volume_plugin/powerstripflocker/test/test_acceptance.py#L242) is a link to the plugin
 * [here](https://github.com/ClusterHQ/powerstrip-flocker/blob/testing_combined_volume_plugin/extra-vagrant-acceptance-targets/ubuntu-14.04/Vagrantfile) is a link to the vagrant setup for a Flocker cluster
 * [here](http://storage.googleapis.com/experiments-clusterhq/docker-volume-extensions/docker) is a link to the latest docker binary that is compiled to understand volume extensions

## setup

There is a folder for each of the integration tests:

 * [swarm](swarm)
 * [k8s](k8s)
 * [mesosphere](mesosphere) (tbc)

## run tests

Each integration has its own test that can be run using `make test` from the integration folder:

```bash
$ cd swarm && make test
```

Or you can use `make test` from the top level to run through all 3:

```bash
$ make test
```