#!/bin/bash

echo "Get sarsys-ops-server status - rollout"
kubectl -n sarsys rollout status statefulset sarsys-ops-server
echo "---------------------------"

echo "Get sarsys-ops-server status - rollout history"
kubectl -n sarsys rollout history statefulset sarsys-ops-server
echo "---------------------------"

echo "Get sarsys-ops-server status - free space | sarsys-ops-server-0"
kubectl -n sarsys exec sarsys-ops-server-0 df
echo "---------------------------"

echo "Get sarsys-ops-server status - free space | sarsys-ops-server-1"
kubectl -n sarsys exec sarsys-ops-server-1 df
echo "---------------------------"

echo "Get sarsys-ops-server status - free space | sarsys-ops-server-2"
kubectl -n sarsys exec sarsys-ops-server-2 df
echo "---------------------------"

echo "Describe pod sarsys-ops-server-0"
kubectl describe pod sarsys-ops-server-0 -n sarsys
echo "---------------------------"

echo "Describe pod sarsys-ops-server-1"
kubectl describe pod sarsys-ops-server-1 -n sarsys
echo "---------------------------"

echo "Describe pod sarsys-ops-server-2"
kubectl describe pod sarsys-ops-server-2 -n sarsys
echo "---------------------------"

echo "Get resource usage | all pods"
kubectl top pod sarsys-ops-server-0 -n sarsys --containers
kubectl top pod sarsys-ops-server-1 -n sarsys --containers | grep  sarsys-ops-server-1
kubectl top pod sarsys-ops-server-2 -n sarsys --containers | grep  sarsys-ops-server-2
echo "---------------------------"

echo "[✓] sarsys-ops-server status completed"
