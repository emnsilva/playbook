#!/bin/bash

# Atualiza os pacotes existentes
echo "Atualizando pacotes do sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar as ferramentas necessárias
echo "Instalando KVM, Vagrant, Git, Python e Visual Studio Code..."
sudo apt install -y qemu qemu-kvm libvirt-daemon libvirt-clients bridge-utils virt-manager git python3 python3-pip

# Adicionar o usuário atual ao grupo libvirt e kvm para gerenciar KVM
echo "Adicionando o usuário aos grupos libvirt e kvm..."
sudo usermod -aG libvirt,kvm $(whoami)

# Instalar Vagrant (necessita de repositorio extra)
echo "Configurando repositório e instalando Vagrant..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install -y vagrant

# Instalar Visual Studio Code (necessita de repositorio extra)
echo "Configurando repositório e instalando Visual Studio Code..."
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null
echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update && sudo apt install -y code

# Reiniciar o serviço libvirtd para aplicar mudanças
echo "Reiniciando serviços necessários..."
sudo systemctl restart libvirtd

echo "Instalação concluída. Todas as ferramentas necessárias foram instaladas com sucesso!"