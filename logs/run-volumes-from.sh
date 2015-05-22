sudo docker run \
  --name base-volume \
  -v apples:/data \
  --volume-driver=flocker \
  busybox sh -c "echo hello > /data/file.txt"

sudo docker run \
  --name use-volume \
  --volumes-from base-volume \
  busybox sh -c "cat /data/file.txt"