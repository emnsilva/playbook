#!/bin/bash
# Ministerio da Observabilidade - Instalador Oficial

set -euo pipefail

[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

echo "[→] Determinando Sistema Operacional..."
if grep -qiE 'debian|ubuntu' /etc/os-release; then
    apt update
    PKG_INSTALL="apt install -y"
elif grep -qiE 'centos|rhel|fedora' /etc/os-release; then
    PKG_INSTALL="yum install -y"
else
    echo "[✗] Sistema não reconhecido" && exit 1
fi

echo "[→] Instalando Ferramentas..."
$PKG_INSTALL curl golang-go docker.io

echo "[→] Configurando o Sistema de Orquestracao..."
DOCKER_COMPOSE_VERSION="v2.27.0"
curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "[→] Baixando Instrumentos de Vigilancia Oficiais..."
for img in prom/prometheus nginx:latest postgres:15 alexeiled/stress-ng:latest netdata/netdata prom/node-exporter; do
    docker pull $img
done

echo "[→] Ativando Servico de Vigilancia Continua..."
systemctl enable --now docker
usermod -aG docker $SUDO_USER 2>/dev/null || true

# Ativacao imediata do grupo Docker (Decreto de Emergencia 9.10.1)
echo "[→] Aplicando Permissoes do Ministerio..."
newgrp docker <<EONG
echo "[→] Permissoes de Vigilancia ativadas para sessao atual"
EONG

echo -e "\n[✔] INFRAESTRUTURA DE VIGILANCIA OPERACIONAL:"
echo "    Go: $(go version 2>/dev/null || echo 'N/A')"
echo "    Docker: $(docker --version 2>/dev/null || echo 'N/A')"
echo "    Docker Compose: $(docker-compose --version 2>/dev/null || echo 'N/A')"

echo -e "\nO Ministerio declara o sistema pronto para coleta de metricas."
