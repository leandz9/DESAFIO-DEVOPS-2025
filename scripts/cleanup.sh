#!/bin/bash

echo "Iniciando limpeza completa do Minikube..."

# Remover instalações Helm
echo "Removendo instalações Helm..."
helm list --short | xargs -L1 helm delete

# Remover todos os recursos
echo "Removendo todos os recursos Kubernetes..."
kubectl delete all --all --all-namespaces

# Remover recursos que não são capturados pelo 'all'
echo "Removendo ConfigMaps, Secrets, PVs, PVCs..."
kubectl delete configmaps,secrets --all --all-namespaces
kubectl delete pv,pvc --all --all-namespaces
kubectl delete ingress --all --all-namespaces

# Remover CRDs e recursos RBAC
echo "Removendo CRDs, ServiceAccounts, Roles..."
kubectl delete serviceaccounts,roles,rolebindings,clusterroles,clusterrolebindings --all --all-namespaces

# Parar o Minikube
echo "Parando o Minikube..."
minikube stop

# Deletar o Minikube
echo "Deletando o Minikube..."
minikube delete

# Limpar Docker
echo "Limpando imagens Docker não utilizadas..."
docker system prune -af

# Iniciar um novo Minikube
echo "Iniciando um novo Minikube..."
minikube start --cpus=4 --memory=4096 --disk-size=20g

echo "Limpeza completa! Minikube reiniciado e pronto para uso."