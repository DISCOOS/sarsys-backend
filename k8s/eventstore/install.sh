#!/bin/bash

echo "1) Add EventStore repo to helm"
helm repo add eventstore https://eventstore.github.io/EventStore.Charts
helm repo update
echo "[✓] Helm updated"

echo "2) Install EventStore"
helm install --namespace sarsys -n eventstore eventstore/eventstore -f eventstore.yaml
kubectl -n sarsys rollout status statefulset eventstore
echo "[✓] EventStore installed"
