#!/bin/bash

# Port-forward services em segundo plano
kubectl port-forward svc/app1-service 5000:80 > /dev/null 2>&1 &
PID_APP1=$!
echo "Port-forward app1 rodando na porta 5000 (PID=$PID_APP1)"

kubectl port-forward svc/app2-service 3000:80 > /dev/null 2>&1 &
PID_APP2=$!
echo "Port-forward app2 rodando na porta 3000 (PID=$PID_APP2)"

# Aguarda port-forward estabilizar
sleep 3

# Funções de simulação
simulate_app1() {
  while true; do
    curl -s http://localhost:5000/text > /dev/null
    curl -s http://localhost:5000/time > /dev/null
    sleep 1
  done
}

simulate_app2() {
  while true; do
    curl -s http://localhost:3000/text > /dev/null
    curl -s http://localhost:3000/time > /dev/null
    sleep 1
  done
}

# Executa em paralelo
simulate_app1 &
simulate_app2 &

# Aguarda Ctrl+C para encerrar
trap "echo 'Encerrando...'; kill $PID_APP1 $PID_APP2; exit" SIGINT
wait
