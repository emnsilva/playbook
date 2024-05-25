#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root"
  exit 1
fi

# Criar o usuário vagrant com a senha vagrant, sem prompt
if grep -q "pam_pwquality.so" /etc/pam.d/common-password; then
  sed -i 's/\(password.*requisite.*pam_pwquality.so\).*/\1 retry=3/' /etc/pam.d/common-password
fi

# Adicionar regra ao sudoers para evitar pedidos de senha para o usuário atual
CURRENT_USER=$(logname)
echo "$CURRENT_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$CURRENT_USER
chmod 440 /etc/sudoers.d/$CURRENT_USER

# Adicionar o usuário vagrant ao grupo sudo
usermod -aG sudo vagrant

# Criar o diretório .ssh no home do usuário vagrant
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh

# Baixar a chave pública do vagrant e adicioná-la ao arquivo authorized_keys
apt-get update -y
apt-get install -y curl
curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Desabilitar a senha sudo para o usuário vagrant
echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant

echo "Usuário vagrant criado e configurado com sucesso."

# Limpa os arquivos temporários e desliga a VM
sudo apt-get clean
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo rm -f /var/log/wtmp /var/log/btmp
sudo history -c

sudo shutdown -h now
