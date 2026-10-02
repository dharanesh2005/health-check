#!/usr/bin/env bash

# health-check.sh
# Usage:
#   ./health-check.sh
#   ./health-check.sh explain

cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | tail -1 | awk -F'id,' '{print 100 - $2}' | cut -d'%' -f1 | tr -d ' ')
cpu_usage=$(printf "%.0f" "$cpu_usage")

if [ -z "$cpu_usage" ] || ! [[ "$cpu_usage" =~ ^[0-9]+$ ]]; then
  cpu_usage=0
fi

mem_total=$(free -m | awk '/^Mem:/ {print $2}')
mem_used=$(free -m | awk '/^Mem:/ {print $3}')

if [ -n "$mem_total" ] && [ "$mem_total" -gt 0 ]; then
  mem_usage=$(( (mem_used * 100) / mem_total ))
else
  mem_usage=0
fi

storage_usage=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')
if [ -z "$storage_usage" ]; then
  storage_usage=0
fi

ram_usage="$mem_usage"

# Health score = average of available capacity
cpu_free=$((100 - cpu_usage))
mem_free=$((100 - mem_usage))
storage_free=$((100 - storage_usage))
ram_free=$((100 - ram_usage))

health_score=$(( (cpu_free + mem_free + storage_free + ram_free) / 4 ))

if [ "$health_score" -lt 60 ]; then
  status="unhealthy"
else
  status="healthy"
fi

print_details() {
  echo "CPU usage     : ${cpu_usage}%"
  echo "Memory usage  : ${mem_usage}%"
  echo "RAM usage     : ${ram_usage}%"
  echo "Storage usage : ${storage_usage}%"
  echo "Health score  : ${health_score}%"
  echo "Status        : ${status}"
}

if [ "${1:-}" = "explain" ]; then
  echo "if health < 60"
  echo "  ${status}"
  echo "  display the CPU, memory, RAM, and storage details"
  echo "else"
  echo "  ${status}"
  echo
  print_details
else
  echo "if health < 60"
  echo "  ${status}"
  echo "else"
  echo "  ${status}"
fi
