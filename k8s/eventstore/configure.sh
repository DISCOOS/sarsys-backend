##!/bin/bash

# 1) Configure eventstore-{node}
echo  "kubectl -n sarsys exec -it eventstore-{node} /bin/bash"
echo  "prlimit --pid 1 --nofile=2048:2048"
echo  "exit"

echo "[✓] EventStore configured"
