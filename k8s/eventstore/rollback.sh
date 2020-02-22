#!/bin/bash

echo "Rollback last EventStore upgrade"
helm rollback eventstore 0
kubectl -n sarsys rollout status statefulset eventstore
echo "[✓] EventStore rollback completed"
