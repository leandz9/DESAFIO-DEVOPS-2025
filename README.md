# 🚀 Desafio DevOps 2025

Este repositório apresenta a solução completa para o Desafio DevOps 2025, abrangendo aplicações Python e Node.js, monitoramento com Prometheus e Grafana, cache utilizando Redis, simulação de carga e scripts de automação em shell script.

---

## 📦 Estrutura do Projeto

```
DESAFIO-DEVOPS-2025/
├── apps/
│   ├── app1-python/
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── app2-node/
│       ├── Dockerfile
│       ├── index.js
│       ├── package.json
│       └── package-lock.json
├── diagramas/
│   ├── arquitetura.drawio
│   └── arquitetura.png
├── infra/
│   └── k8s/
│       ├── app1-deployment.yaml
│       ├── app2-deployment.yaml
│       ├── configmap.yaml
│       ├── grafana-values.yaml
│       ├── ingress.yaml
│       ├── prometheus-values.yaml
│       └── redis-deployment.yaml
├── scripts/
│   ├── check-redis-cache.sh
│   ├── cleanup.sh
│   ├── simulate-traffic.sh
│   └── start.sh
├── .gitignore
└── README.md
```

---

## ⚙️ Tecnologias Utilizadas

- Kubernetes (Minikube)
- Docker
- Prometheus
- Grafana
- Redis
- Python (Flask)
- Node.js (Express)
- Shell Script (Bash)

---

## 🧐 Funcionalidades

- Aplicativos expondo métricas customizadas em `/metrics`
- Sistema de cache com Redis (com contadores de cache hit/miss)
- Dashboards automáticos no Grafana via `ConfigMap`
- Scripts para configuração, simulação de carga e limpeza de ambiente
- Simulação de tráfego para gerar métricas em tempo real
- Scripts auxiliares para inspeção do cache em Redis

---

## 📌 Arquitetura da Solução

![Arquitetura](./diagramas/arquitetura.png)

---

## ▶️ Como Executar

1. Clone o repositório:
```bash
git clone https://github.com/seuusuario/desafio-devops-2025.git
cd desafio-devops-2025/scripts
```

2. Execute o script de inicialização:
```bash
chmod +x start.sh
./start.sh
```

3. Acesse os serviços:
```
App1 (Python):    http://app1.local
App2 (Node.js):   http://app2.local
Prometheus:       http://<minikube-ip>:<porta>
Grafana:          http://<minikube-ip>:<porta> (usuário: admin / senha: admin)
```

**Observação:** o script `start.sh` atualiza automaticamente o `/etc/hosts` adicionando os domínios locais.

---

## 🌐 Simulação de Tráfego

Para gerar tráfego real para as aplicações:
```bash
cd scripts
chmod +x simulate-traffic.sh
./simulate-traffic.sh
```

O script realiza port-forwarding e gera requisições simuladas em tempo real para `/text` e `/time` de ambas as aplicações.


## 🔍 Verificação do Cache Redis

Para inspecionar as chaves de cache diretamente no Redis:
```bash
chmod +x check-redis-cache.sh
./check-redis-cache.sh
```

O script conecta no Redis rodando no Minikube e exibe as entradas de cache utilizadas pelas aplicações.

---

## 🛋️ Cleanup do Ambiente

Para remover todos os recursos criados:
```bash
./cleanup.sh
```

Este script garante a limpeza de todas as aplicações, serviços, ingressos e instalações Helm.

---

## 📸 Dashboards no Grafana

- [x] Contador de requisições por endpoint
- [x] Taxa de Cache Hit vs Cache Miss
- [x] Latência (p95) via histogram
- [x] Dashboards Kubernetes para pods, nodes e namespaces

Os dashboards foram provisionados automaticamente através do Helm.

---

## 📝 Observações Importantes

- Todas as métricas estão agrupadas dinamicamente por `instance`, permitindo identificar diferentes fontes.
- O acesso às aplicações é realizado através do Ingress configurado para `app1.local` e `app2.local`.
- O Prometheus realiza a coleta tanto via `kubernetes_sd_configs` quanto via `static_configs` para compatibilidade local.
- A exposição de serviços no Minikube é feita via NodePort para Grafana e Prometheus.

### 💡 Melhorias Futuras

- Implementação de Cert-Manager para gerenciamento de certificados TLS automáticos.
- Utilização de namespaces dedicados para isolamento de aplicações.
- Integração de pipelines CI/CD para build e deploy automático dos apps.
- Configurar dashboards mais avançados para latência detalhada, erro rate e throughput.


---

## 👨‍💼 Autor

Leandro Santana — DevOps/SRE & Especialista em Cloud Computing

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Perfil-blue)](https://www.linkedin.com/in/leandro-santana-da-silva-3a557a220/)

---

💥 Powered by Open Source • Desafio Proposto em 2025

