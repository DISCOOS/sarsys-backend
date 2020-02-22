#!/bin/bash

echo "Get eventstore status"
kubectl -n sarsys rollout status statefulset eventstore
kubectl -n sarsys rollout history statefulset eventstore
echo "[✓] EventStore status completed"
