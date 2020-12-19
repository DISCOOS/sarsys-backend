#!/bin/bash

echo "Get eventstore status - rollout"
kubectl -n sarsys rollout status statefulset eventstore
echo "---------------------------"

echo "Get eventstore status - rollout history"
kubectl -n sarsys rollout history statefulset eventstore
echo "---------------------------"

# Howto resize PVC see https://github.com/EventStore/EventStore.Charts/tree/master/stable/eventstore#option-1-resize-pvc-created-with-volume-expansion-enabled

echo "Get eventstore status - free space | eventstore-0"
kubectl -n sarsys exec eventstore-0 df
echo "---------------------------"

echo "Get eventstore status - free space | eventstore-1"
kubectl -n sarsys exec eventstore-1 df
echo "---------------------------"

echo "Get eventstore status - free space | eventstore-2"
kubectl -n sarsys exec eventstore-2 df
echo "---------------------------"

echo "Describe pod eventstore-0"
kubectl describe pod eventstore-0 -n sarsys
echo "---------------------------"

echo "Describe pod eventstore-1"
kubectl describe pod eventstore-1 -n sarsys
echo "---------------------------"

echo "Describe pod eventstore-2"
kubectl describe pod eventstore-2 -n sarsys
echo "---------------------------"

echo "Get resource usage | all pods"
kubectl top pod eventstore-0 -n sarsys --containers
kubectl top pod eventstore-1 -n sarsys --containers | grep eventstore-1
kubectl top pod eventstore-2 -n sarsys --containers | grep eventstore-2

echo "[✓] EventStore status completed"
