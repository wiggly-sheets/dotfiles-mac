#!/bin/bash
# Fetch GPU usage from powermetrics
gpu_usage=$(sudo powermetrics --samplers cpu_power | grep "GPU" | awk '{print $2}' | tr -d '[:space:]')
echo "$gpu_usage"

