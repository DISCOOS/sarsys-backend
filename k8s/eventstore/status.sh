#!/bin/bash

echo "Get eventstore status - rollout"
kubectl -n sarsys rollout status statefulset eventstore

echo "Get eventstore status - rollout history"
kubectl -n sarsys rollout history statefulset eventstore

# Howto resize PVC see https://github.com/EventStore/EventStore.Charts/tree/master/stable/eventstore#option-1-resize-pvc-created-with-volume-expansion-enabled

echo "Get eventstore status - free space | eventstore-0"
kubectl -n sarsys exec eventstore-0 df

echo "Get eventstore status - free space | eventstore-1"
kubectl -n sarsys exec eventstore-1 df

echo "Get eventstore status - free space | eventstore-2"
kubectl -n sarsys exec eventstore-2 df

echo "Get resource usage | all pods"
kubectl top pod sarsys-app-server-0 -n sarsys --containers
kubectl top pod sarsys-app-server-1 -n sarsys --containers
kubectl top pod sarsys-app-server-2 -n sarsys --containers

echo "[✓] EventStore status completed"
