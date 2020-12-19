#!/bin/bash

echo "Get sarsys-app-server status - rollout"
kubectl -n sarsys rollout status statefulset sarsys-app-server

echo "Get sarsys-app-server status - rollout history"
kubectl -n sarsys rollout history statefulset sarsys-app-server

echo "Get sarsys-app-server status - free space | sarsys-app-server-0"
kubectl -n sarsys exec sarsys-app-server-0 df

echo "Get sarsys-app-server status - free space | sarsys-app-server-1"
kubectl -n sarsys exec sarsys-app-server-1 df

echo "Get sarsys-app-server status - free space | sarsys-app-server-2"
kubectl -n sarsys exec sarsys-app-server-2 df

echo "Get resource usage | all pods"
kubectl top pod sarsys-app-server-0 -n sarsys --containers
kubectl top pod sarsys-app-server-1 -n sarsys --containers | grep  sarsys-app-server-1
kubectl top pod sarsys-app-server-2 -n sarsys --containers | grep  sarsys-app-server-2

echo "[✓] sarsys-app-server status completed"
