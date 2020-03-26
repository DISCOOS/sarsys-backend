#!/bin/bash

echo "Open http://localhost:2113/web"
kubectl -n sarsys port-forward svc/eventstore-admin 2113
