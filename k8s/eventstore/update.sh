#!/bin/bash

echo "Update EventStore"
helm upgrade eventstore eventstore/eventstore -f eventstore.yaml
echo "[✓] EventStore updated"
