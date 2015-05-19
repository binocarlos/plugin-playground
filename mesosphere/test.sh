#!/bin/bash

unixsecs=$(date +%s)

export MARATHON_HOST=${MARATHON_HOST:=http://172.16.255.240:8080}
export APP_HOST=${APP_HOST:=http://172.16.255.241:8000}

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_SRC="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

check-equals() {
  if [[ "$1" != "$2" ]]; then
    echo "$1 != $2" 1>&2
    exit 1
  fi
}

# parse the Marathon output for the status of a task
is-mesos-task-running() {
  curl -sS $MARATHON_HOST/v2/apps/$1 | jq .app.tasksRunning
}

# continue to loop over is-mesos-task-running until it is ready
wait-for-mesos-task() {
  local running=$(is-mesos-task-running $1)
  while [[ "$running" == "null" ]]
  do
    echo "wait for mesos task $1" && sleep 1    
    running=$(is-mesos-task-running $1)
  done
  echo "mesos task $1 is running"
  sleep 5
}

# told which node and which container - this will ssh to the node and
# run docker ps with a 'running' filter and grep the container name
is-docker-container-running() {
  local node=$1
  local container=$2
  vagrant ssh $node -c "sudo docker ps --filter \"status=running\" | grep $container"
}


# keep looping over `is-docker-container-running` until it is
wait-for-docker-container() {
  local node=$1
  local container=$2
  local running=$(is-docker-container-running $node $container)
  while [[ -z "$running" ]]
  do
    echo "waiting for docker container $container on $node"
    running=$(is-docker-container-running $node $container)
  done
  echo "docker container $container on node $node is running"
  sleep 1
}

# combine wait-for-mesos-task and wait-for-docker-container
wait-for-job() {
  local task=$1
  local node=$2
  local container=$3

  echo ""
  echo "waiting for job $task - $node - $container"

  wait-for-mesos-task $task
  echo "waiting for docker container"
  wait-for-docker-container $node $container
}


launch-app() {
  local disk=$1;

  echo "launching app - $disk"

  cat $SCRIPT_SRC/example/app.json | \
  sed "s/\"id\":\"app\"/\"id\":\"app-$unixsecs\"/" | \
  sed "s/flocker\/testdata/flocker\/testdata$unixsecs/" | \
  sed "s/spinning/$disk/" | \
  curl -i -H 'Content-type: application/json' -d @- $MARATHON_HOST/v2/apps
}


# tell marathon to delete an app
delete-app() {
  echo "Deleting app $1"
  curl -X "DELETE" $MARATHON_HOST/v2/apps/$1
  echo ""
}

# grab a list of apps from Marathon and remove each on if its id starts with mongo- or app-
function delete-apps() {
  local totalapps=$(curl -sS $MARATHON_HOST/v2/apps | jq '.apps | length')

  echo "Found $totalapps apps"
  local COUNTER=0
  local DELETEAPPS=()
  while [  $COUNTER -lt $totalapps ]; do

    echo "Getting id for app $COUNTER"
    local appid=$(curl -sS $MARATHON_HOST/v2/apps | jq ".apps[$COUNTER].id" | sed 's/"//g')

    echo "Found $appid"
    
    if [[ "$appid" == *"/mongo-"* ]] || [[ "$appid" == *"/app-"* ]]; then
      DELETEAPPS+=($appid)
    fi

    echo "$appid app deleted"

    let COUNTER+=1
  done

  for deleteapp in "${DELETEAPPS[@]}"
  do
    delete-app $deleteapp
  done
}


echo "removing existing Marathon apps"
delete-apps
echo "launching app on node1"
launch-app spinning
echo "waiting for docker container on node1"
wait-for-job app-$unixsecs node1 binocarlos/hello-increment:latest

sleep 5

# increment and test the values
counter=$(curl -sSL http://172.16.255.241:8000)
echo "load first value (node1): $counter"
check-equals $counter 1
counter=$(curl -sSL http://172.16.255.241:8000)
echo "load second value (node1): $counter"
check-equals $counter 2
counter=$(curl -sSL http://172.16.255.241:8000)
echo "load third value (node1): $counter"
check-equals $counter 3

echo "Removing app from node1"
delete-app app-$unixsecs

sleep 5

echo "launching app on node2"
launch-app ssd
echo "waiting for docker container on node2"
wait-for-job app-$unixsecs node2 binocarlos/hello-increment:latest

# increment and test the values
counter=$(curl -sSL http://172.16.255.242:8000)
echo "load fourth value (node2): $counter"
check-equals $counter 4
counter=$(curl -sSL http://172.16.255.242:8000)
echo "load fith value (node2): $counter"
check-equals $counter 5
counter=$(curl -sSL http://172.16.255.242:8000)
echo "load sixth value (node3): $counter"
check-equals $counter 6

echo "removing existing Marathon apps"
delete-apps

echo
echo "all tests passed"
exit 0