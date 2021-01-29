#!/bin/bash

echo "Download sarsys-ops-server snapshots..."
mkdir -p .data
kubectl -n sarsys cp sarsys/sarsys-ops-server-0:/var/lib/sarsys/ .data/server-0
kubectl -n sarsys cp sarsys/sarsys-ops-server-0:/var/lib/sarsys/ .data/server-1
kubectl -n sarsys cp sarsys/sarsys-ops-server-0:/var/lib/sarsys/ .data/server-2
echo "Analysing folder '.data'"
ls -al .data
echo "[✓] Downloading finished"
