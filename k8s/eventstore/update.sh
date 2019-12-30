#!/bin/bash

echo "Update EventStore"
helm upgrade eventstore eventstore/eventstore -f eventstore.yaml
kubectl -n sarsys rollout status statefulset eventstore
echo "[✓] EventStore updated"
