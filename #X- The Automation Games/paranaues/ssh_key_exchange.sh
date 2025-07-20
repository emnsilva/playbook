#!/bin/bash

# Ler variáveis do arquivo JSON usando jq
CONFIG_FILE="config.json"
USER=$(jq -r '.USER' ${CONFIG_FILE})
HOST_IP=$(jq -r '.HOST_IP' ${CONFIG_FILE})
VM_IP=$(jq -r '.VM_IP' ${CONFIG_FILE})
SSH_DIR=$(jq -r '.SSH_DIR' ${CONFIG_FILE})
PASSWORD=$(jq -r '.PASSWORD' ${CONFIG_FILE})

# Função para gerar chaves SSH
generate_ssh_key() {
  local ip=$1

  if [ -z "${ip}" ]; then
    # Gera chaves no Host
    ssh-keygen -t rsa -b 4096 -f "${SSH_DIR}/id_rsa" -N ""
  else
    # Gera chaves na VM
    sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no ${USER}@${ip} "ssh-keygen -t rsa -b 4096 -f ${SSH_DIR}/id_rsa -N ''"
  fi
}

# Função para copiar a chave pública de uma máquina para outra
copy_ssh_key() {
  local src_ip=$1
  local dest_ip=$2
  local key_name=$3

  sshpass -p "${PASSWORD}" scp -o StrictHostKeyChecking=no ${SSH_DIR}/id_rsa.pub ${USER}@${dest_ip}:${SSH_DIR}/${key_name}
}

# Função para adicionar a chave pública ao arquivo authorized_keys
add_to_authorized_keys() {
  local ip=$1
  local key_name=$2

  if [ -z "${ip}" ]; then
    # Adiciona no Host
    cat ${key_name} >> ${SSH_DIR}/authorized_keys
  else
    # Adiciona na VM
    sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no ${USER}@${ip} "cat ${SSH_DIR}/${key_name} >> ${SSH_DIR}/authorized_keys"
  fi
}

# =======================================================
# Execução Principal do Script
# =======================================================

# Gerar chaves no Host e na VM
generate_ssh_key ""
generate_ssh_key "${VM_IP}"

# Copiar chave pública do Host para a VM e adicionar ao authorized_keys
copy_ssh_key "" "${VM_IP}" "host_id_rsa.pub"
add_to_authorized_keys "${VM_IP}" "host_id_rsa.pub"

# Copiar chave pública da VM para o Host e adicionar ao authorized_keys
copy_ssh_key "${VM_IP}" "${HOST_IP}" "vm_id_rsa.pub"
add_to_authorized_keys "" "${VM_PUBLIC_KEY}"

echo "Troca de chaves SSH concluída com sucesso!"
