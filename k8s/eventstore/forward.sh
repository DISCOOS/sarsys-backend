#!/bin/bash

echo "Open http://127.0.0.1:2113/web"
kubectl -n sarsys port-forward svc/eventstore-admin 2113
