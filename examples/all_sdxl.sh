#!/bin/bash

set -e

cd "$(dirname "$0")"

LOG_DIR="$(pwd)/all_sdxl_logs"
mkdir -p "$LOG_DIR"

echo "=== Launching 11 SDXL training jobs in parallel (background) ==="
echo "Logs: $LOG_DIR/sdxl_<N>.log"
echo "Container names: image-trainer-1 ... image-trainer-11"
echo

for i in 1 2 3 4 5 6 7 8 9 10 11; do
    echo "Starting sdxl_${i}.sh → $LOG_DIR/sdxl_${i}.log"
    bash "sdxl_${i}.sh" > "$LOG_DIR/sdxl_${i}.log" 2>&1 &
done

echo
echo "All 11 jobs launched. Waiting for completion..."
echo "Monitor live: tail -f $LOG_DIR/sdxl_<N>.log"
echo "Check container status: docker ps -a | grep image-trainer-"
echo

wait

echo
echo "=== All 11 SDXL training jobs complete ==="
echo "Review logs di: $LOG_DIR/"
