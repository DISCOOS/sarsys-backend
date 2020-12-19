#!/bin/bash

echo "Get sarsys-tracking-server status - rollout"
kubectl -n sarsys rollout status statefulset sarsys-tracking-server
echo "---------------------------"

echo "Get sarsys-tracking-server status - rollout history"
kubectl -n sarsys rollout history statefulset sarsys-tracking-server
echo "---------------------------"

echo "Get sarsys-tracking-server status - free space | sarsys-tracking-server-0"
kubectl -n sarsys exec sarsys-tracking-server-0 df
echo "---------------------------"

echo "Get sarsys-tracking-server status - free space | sarsys-tracking-server-1"
kubectl -n sarsys exec sarsys-tracking-server-1 df
echo "---------------------------"

echo "Get sarsys-tracking-server status - free space | sarsys-tracking-server-2"
kubectl -n sarsys exec sarsys-tracking-server-2 df
echo "---------------------------"

echo "Describe pod sarsys-tracking-server-0"
kubectl describe pod sarsys-tracking-server-0 -n sarsys
echo "---------------------------"

echo "Describe pod sarsys-tracking-server-1"
kubectl describe pod sarsys-tracking-server-1 -n sarsys
echo "---------------------------"

echo "Describe pod sarsys-tracking-server-2"
kubectl describe pod sarsys-tracking-server-2 -n sarsys
echo "---------------------------"

echo "Get resource usage | all pods"
kubectl top pod sarsys-tracking-server-0 -n sarsys --containers
kubectl top pod sarsys-tracking-server-1 -n sarsys --containers | grep  sarsys-tracking-server-1
kubectl top pod sarsys-tracking-server-2 -n sarsys --containers | grep  sarsys-tracking-server-2
echo "---------------------------"

echo "[✓] sarsys-tracking-server status completed"
