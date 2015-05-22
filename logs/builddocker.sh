docker build -t custom-docker .
docker run --privileged --rm -e DOCKER_EXPERIMENTAL=1 -e DOCKER_GITCOMMIT=`git log -1 --format=%h` -v `pwd`:/go/src/github.com/docker/docker custom-docker hack/make.sh binary