#!/bin/bash

echo "1) Uninstall eventstore"
helm delete eventstore --purge

echo "2) Manually delete PersistentVolumeClaims"
kubectl -n sarsys get pvc | grep data-eventstore-

echo "3) Manually delete PersistentVolumes"
kubectl -n sarsys get pv | grep sarsys/data-eventstore-

echo "[✓] EventStore uninstalled"
