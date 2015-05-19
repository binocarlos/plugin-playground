.PHONY: test

test:
	cd swarm && make test
	cd k8s && make test

