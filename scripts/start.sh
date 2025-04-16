#!/bin/bash

# Definir diretório base
BASE_DIR="$(cd ..; pwd)"

# Verificar se o minikube está instalado
if ! command -v minikube &> /dev/null; then
    echo "Minikube não encontrado. Por favor, instale o minikube primeiro."
    exit 1
fi

# Verificar se o Helm está instalado
if ! command -v helm &> /dev/null; then
    echo "Helm não encontrado. Por favor, instale o Helm primeiro."
    exit 1
fi

# Iniciar minikube se não estiver rodando
if ! minikube status | grep -q "Running"; then
    echo "Iniciando minikube..."
    minikube start --cpus=4 --memory=4096 --disk-size=20g
fi

# Habilitar addons necessários
echo "Habilitando addons no minikube..."
minikube addons enable ingress
minikube addons enable metrics-server

# Configurar o Docker para usar o daemon do Minikube
echo "Configurando Docker para usar daemon do Minikube..."
eval $(minikube docker-env)

# Adicionar repositórios Helm
echo "Adicionando repositórios Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Construir imagens Docker
echo "Construindo imagens Docker..."
docker build -t app1-python:latest "${BASE_DIR}/apps/app1-python/"
docker build -t app2-node:latest "${BASE_DIR}/apps/app2-node/"

# Aplicar configurações do Kubernetes
echo "Aplicando configuração do Redis..."
kubectl apply -f "${BASE_DIR}/infra/k8s/redis-deployment.yaml"

echo "Aplicando configuração das aplicações..."
kubectl apply -f "${BASE_DIR}/infra/k8s/app1-deployment.yaml"
kubectl apply -f "${BASE_DIR}/infra/k8s/app2-deployment.yaml"

echo "Aplicando configurações de Ingress..."
kubectl apply -f "${BASE_DIR}/infra/k8s/ingress.yaml"

# Instalar Grafana com Helm
helm install grafana grafana/grafana -f "${BASE_DIR}/infra/k8s/grafana-values.yaml" --set service.type=NodePort

# Instalar Prometheus com Helm
echo "Instalando Prometheus com Helm..."
helm install prometheus prometheus-community/prometheus -f "${BASE_DIR}/infra/k8s/prometheus-values.yaml"

# Aguardar serviços básicos estarem prontos
echo "Aguardando a inicialização do Redis..."
kubectl wait --for=condition=available --timeout=60s deployment/redis

echo "Aguardando a inicialização da app1..."
kubectl wait --for=condition=available --timeout=60s deployment/app1-python || true

echo "Aguardando a inicialização da app2..."
kubectl wait --for=condition=available --timeout=60s deployment/app2-node || true

echo "Aguardando a inicialização do Prometheus..."
PROM_DEPLOY=$(kubectl get deploy -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')
kubectl wait --for=condition=available --timeout=300s deployment/$PROM_DEPLOY


echo "Aguardando a inicialização do Grafana..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana || true

# Verificar pods com problemas
echo "Verificando pods com problemas..."
kubectl get pods

# Adicionar entradas no /etc/hosts
echo "Atualizando /etc/hosts com domínios locais..."
MINIKUBE_IP=$(minikube ip)

# Remove linhas antigas (se existirem)
sudo sed -i '/app1.local/d' /etc/hosts
sudo sed -i '/app2.local/d' /etc/hosts

# Adiciona entrada atualizada
echo "$MINIKUBE_IP app1.local app2.local" | sudo tee -a /etc/hosts


# Obter informações das portas
echo "Obtendo informações das portas..."
PROMETHEUS_PORT=$(kubectl get svc prometheus-server -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "não disponível")
GRAFANA_PORT=$(kubectl get svc grafana -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "não disponível")

# Exibir informações de acesso
echo -e "\n==== Aplicações disponíveis em: ===="
echo "App1 (Python): http://app1.local"
echo "App2 (Node.js): http://app2.local"
echo "Prometheus: http://$MINIKUBE_IP:$PROMETHEUS_PORT"
echo "Grafana: http://$MINIKUBE_IP:$GRAFANA_PORT (login: admin, senha: admin)"
echo "===================================="

echo "Pressione Enter para verificar os logs dos pods que estão com problemas..."
read

# Verificar logs de pods com problemas
for pod in $(kubectl get pods | grep -v Running | awk '{print $1}' | grep -v NAME); do
    echo "==== Logs do pod $pod ===="
    kubectl logs $pod
    echo "=========================="
done

