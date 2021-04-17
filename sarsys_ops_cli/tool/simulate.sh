#!/bin/bash


echo "Simulating..."

DUUID='795327348888342b15e97607a05277a00c9d551c5bef34cbab3b87cfe71c69b7';
DCOUNT=$(sarsysctl aggregate search -t device -q="$.data[?(@.uuid=="$DUUID")]" -o json | jq -r '.items' | jq length)
echo "Device $DUUID instances: $DCOUNT";

TUUID='176d539e-d307-4885-833a-a228af77a9d3';
TCOUNT=$(sarsysctl aggregate search -t tracking -q="$.data[?(@.uuid=="$TUUID")]" -o json | jq -r '.items' | jq length)
echo "Tracking $TUUID instances: $TCOUNT";

if [[ $DCOUNT -eq 0 ]]; then
  echo "Device $DUUID not found";
  exit 1
fi
if [[ $TCOUNT -eq 0 ]]; then
  echo "Tracking $TUUID not found";
  exit 2
fi

echo "[✓] sarsys-app-server watch completed"