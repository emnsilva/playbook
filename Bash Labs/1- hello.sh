#!/bin/bash

# Nome do usuário
user=$(whoami)

# Data atual
date_format=$(date +%Y-%m-%d)

# Diretório atual
current_directory=$(pwd)

# Exibir informações
echo "Olá $user, Hoje é dia: $date_format, e você está em: $current_directory"
