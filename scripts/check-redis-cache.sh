#!/bin/bash

REDIS_POD=$(kubectl get pod -l app=redis -o jsonpath="{.items[0].metadata.name}")

# Cores
COLOR_RESET=$(tput sgr0)
COLOR_APP1=$(tput setaf 6) # Ciano para app1
COLOR_APP2=$(tput setaf 5) # Magenta para app2
COLOR_TITLE=$(tput setaf 2) # Verde para titulos

echo "🔍 Monitorando cache do Redis (Ctrl+C para sair)..."
echo ""

while true; do
  clear
  echo "${COLOR_TITLE}🔄 Atualização: $(date)${COLOR_RESET}"
  echo ""

  echo "${COLOR_TITLE}🔑 Listando chaves:${COLOR_RESET}"

  kubectl exec "$REDIS_POD" -- sh -c '
    redis-cli keys "app*" | while read key; do
      value=$(redis-cli get "$key")
      ttl=$(redis-cli ttl "$key")

      if echo "$key" | grep -q "app1"; then
        color="\033[36m"  # Ciano
      elif echo "$key" | grep -q "app2"; then
        color="\033[35m"  # Magenta
      else
        color="\033[0m"   # Default
      fi

      printf "${color}\n🔹 %s\nValor: %s\nTTL: %s segundos\n\033[0m" "$key" "$value" "$ttl"
    done
  '

  sleep 5
done
