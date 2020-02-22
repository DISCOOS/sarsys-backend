#!/bin/bash

echo "Uninstall eventstore"
helm delete eventstore --purge
echo "[✓] EventStore uninstalled"
