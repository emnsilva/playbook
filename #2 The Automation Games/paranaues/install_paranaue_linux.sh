#!/bin/bash

# Atualiza os pacotes e instala pré-requisitos
echo "Atualizando pacotes e instalando pré-requisitos..."
sudo apt update
sudo apt install -y wget apt-transport-https software-properties-common

# Adiciona o repositório do PowerShell
echo "Adicionando o repositório do PowerShell..."
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb

# Instala o PowerShell
echo "Instalando o PowerShell..."
sudo apt update
sudo apt install -y powershell

# Verifica a instalação do PowerShell
echo "Verificando a instalação do PowerShell..."
pwsh -c 'echo "PowerShell instalado com sucesso!"'

# Baixa e instala o OMI (Open Management Infrastructure)
echo "Baixando e instalando o OMI..."
wget https://github.com/microsoft/omi/releases/download/v1.6.10-0/omi-1.6.10-0.ulinux.x64.deb
sudo dpkg -i omi-1.6.10-0.ulinux.x64.deb

# Verifica a instalação do OMI
echo "Verificando a instalação do OMI..."
/opt/omi/bin/omicli ei root/cimv2 OMI_Identify

# Baixa e instala o LCM (Local Configuration Manager)
echo "Baixando e instalando o LCM..."
wget https://github.com/microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1/dsc-1.1.1-294.ulinux.x64.deb
sudo dpkg -i dsc-1.1.1-294.ulinux.x64.deb

# Verifica a instalação do LCM
echo "Verificando a instalação do LCM..."
/opt/microsoft/dsc/Scripts/GetDscConfigurationStatus.py

echo "Instalação concluída!"
