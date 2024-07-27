#!/bin/bash
EMAIL="admin@example.com"
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=90

send_alert() {
  local subject="$1"
  local message="$2"
  echo "$message" | mail -s "$subject" $EMAIL
}

# Monitorar uso de CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
  send_alert "Alerta de Uso de CPU" "O uso de CPU é de ${CPU_USAGE}%."
fi

# Monitorar uso de memória
MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
if (( $(echo "$MEM_USAGE > $MEM_THRESHOLD" | bc -l) )); then
  send_alert "Alerta de Uso de Memória" "O uso de memória é de ${MEM_USAGE}%."
fi

# Monitorar uso de disco
DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')
if [ $DISK_USAGE -gt $DISK_THRESHOLD ]; then
  send_alert "Alerta de Uso de Disco" "O uso do disco é de ${DISK_USAGE}%."
fi