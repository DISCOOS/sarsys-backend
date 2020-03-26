#!/bin/bash

echo "1) Add EventStore repo to helm"
helm repo add eventstore https://eventstore.github.io/EventStore.Charts
helm repo update
echo "[✓] Helm updated"

echo "2) Install Storage Class 'do-block-storage-retain' (default class does not retain)"
kubectl -n sarsys get storageclasses
kubectl -n sarsys apply -f storageclass.yaml

echo "3) Install EventStore"
helm install --namespace sarsys -n eventstore eventstore/eventstore -f eventstore.yaml
kubectl -n sarsys rollout status statefulset eventstore
echo "[✓] EventStore installed"
