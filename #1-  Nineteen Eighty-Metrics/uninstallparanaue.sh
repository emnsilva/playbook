#!/bin/bash
# Ministério da Observabilidade - Removedor Oficial

set -euo pipefail

[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

echo "[→] Revertendo instalação..."

# 1. Remover containers, imagens e volumes Docker
echo "[→] Removendo containers e imagens Docker..."
docker rm -f $(docker ps -aq) 2>/dev/null || true
docker rmi -f $(docker images -q) 2>/dev/null || true
docker volume prune -f

# 2. Desinstalar pacotes
echo "[→] Desinstalando pacotes..."
if grep -qiE 'debian|ubuntu' /etc/os-release; then
    apt purge -y golang-go docker.io docker-compose
    apt autoremove -y
elif grep -qiE 'centos|rhel|fedora' /etc/os-release; then
    yum remove -y golang docker-ce docker-compose-plugin
fi

# 3. Remover arquivos do Docker Compose
echo "[→] Removendo Docker Compose..."
rm -f /usr/local/bin/docker-compose /usr/bin/docker-compose

# 4. Remover grupo Docker e usuário
echo "[→] Removendo grupo Docker..."
groupdel docker 2>/dev/null || true

# 5. Parar e desabilitar serviço Docker
echo "[→] Parando serviços..."
systemctl stop docker.socket docker 2>/dev/null || true
systemctl disable docker 2>/dev/null || true

echo -e "\n[✔] Reversão concluída com sucesso!"
echo "    * Todos os containers e imagens Docker foram removidos"
echo "    * Pacotes (Go, Docker, Docker Compose) desinstalados"
echo "    * Execute 'newgrp' ou reinicie o sistema para atualizar grupos do usuário"