#!/bin/bash

# Usuário atual
CURRENT_USER=$(logname)

# Adicionar regra ao sudoers para evitar pedidos de senha
echo "$CURRENT_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$CURRENT_USER

# Atualizar a lista de pacotes e instalar dependências
sudo apt-get update -y
sudo apt-get install -y wget curl gnupg software-properties-common git python3 python3-pip nfs-kernel-server nfs-common virtualbox

# Instalar Vagrant
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com jammy main"
sudo apt-get update -y
sudo apt-get install -y vagrant

# Instalar VSCode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt-get update -y
sudo apt-get install -y code

# Configurar compartilhamento NFS
SHARE_DIR="/ubuntu/VM"
sudo mkdir -p $SHARE_DIR
sudo chown nobody:nogroup $SHARE_DIR
sudo chmod 777 $SHARE_DIR
echo "$SHARE_DIR *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

# Reiniciar e habilitar os serviços do NFS
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server

# Limpeza
sudo apt-get clean

# Verificar o status do serviço NFS
echo "Status do serviço nfs-kernel-server:"
sudo systemctl is-active nfs-kernel-server

echo "Instalação e configuração concluídas!"
