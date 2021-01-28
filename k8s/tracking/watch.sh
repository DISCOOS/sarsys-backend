#!/bin/bash

echo "Get resource usage | all pods"
while true
do
  kubectl top pod sarsys-tracking-server-0 -n sarsys --containers
  kubectl top pod sarsys-tracking-server-1 -n sarsys --containers | grep  sarsys-tracking-server-1
  kubectl top pod sarsys-tracking-server-2 -n sarsys --containers | grep  sarsys-tracking-server-2
  echo "Waiting for 5s..."
  sleep 5
  echo "---------------------------"
done

echo "[✓] sarsys-tracking-server watch completed"
