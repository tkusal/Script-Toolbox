#!/bin/bash
THRESHOLD=80
USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')

if [ $USAGE -gt $THRESHOLD ]; then
  echo "Alerta: Uso do disco acima de $THRESHOLD%!"
else
  echo "Uso do disco dentro do limite."
fi