DOCKER_HOST=tcp://127.0.0.1:2375 \
docker run -d \
  --name flocker-test \
  -v pears:/data \
  --volume-driver=flocker \
  -p 8080:80 \
  -e constraint:storage==disk \
  -e FILE=/data/testdata.txt \
  binocarlos/hello-increment