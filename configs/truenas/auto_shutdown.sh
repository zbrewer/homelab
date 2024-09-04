#!/bin/bash

echo "Checking for active replication, scrub, or S.M.A.R.T. tasks and shutting down if none are found."

# List of all disks to check for S.M.A.R.T. tests
declare -a disks=("sda" "sdb" "sdc")
current_smart_tests=0
for disk in "${disks[@]}"; do
    current_smart_tests=$((current_smart_tests + $(smartctl -l selftest "/dev/$disk" | grep -cm1 "Self-test routine in progress")))
done

echo "$current_smart_tests S.M.A.R.T. test(s) in progress"

# Check for scrub tasks
current_scrub_tasks=$(zpool status | grep -c "scrub in progress")
echo "$current_scrub_tasks scrub(s) in progress"

# Check for running or failed (non-FINISHED) replication tasks
running_replication_tasks=$(cli -m csv -c "task replication query state" | grep -c "RUNNING")
failed_replication_tasks=$(cli -m csv -c "task replication query state" | grep -c "FAILED")
echo "$running_replication_tasks running and $failed_replication_tasks failed replication task(s)"

if [[ (( $failed_replication_tasks > 0 )) ]]; then
    echo "$failed_replication_tasks replication task(s) failed - attention is required. Not shutting down."
    exit 2
fi

if [[ (( $current_smart_tests > 0 )) || (( $current_scrub_tasks > 0 )) || (( $running_replication_tasks > 0 )) ]]; then
    echo "Tasks running, not shutting down."
    exit 1
else
    echo "No tasks running. Shutting down in 1 minute."
    shutdown -h +1
fi
