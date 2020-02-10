#!/bin/bash

echo "Restart eventstore (k8s version 1.15 or higher)"
kubectl -n sarsys rollout restart statefulset eventstore
kubectl -n sarsys rollout status statefulset eventstore
echo "[✓] EventStore restarted"
