#!/bin/bash

echo "Rollback last EventStore upgrade"
helm rollback eventstore 0
echo "[✓] EventStore rollback completed"
