#!/bin/bash

echo "Get resource usage | all pods"
while true
do
  kubectl top pod eventstore-0 -n sarsys --containers
  kubectl top pod eventstore-1 -n sarsys --containers | grep  eventstore-1
  kubectl top pod eventstore-2 -n sarsys --containers | grep  eventstore-2
  echo "Waiting for 5s..."
  sleep 5
  echo "---------------------------"
done

echo "[✓] eventstore watch completed"