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

echo "[✓] EventStore status completed"
