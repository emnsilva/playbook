#!/bin/bash
# Ministério da Observabilidade - Teste de Resistência Total
SERVICES=$(docker-compose ps --services)

for SERVICE in $SERVICES; do
  echo "[→] Atacando container: $SERVICE"
  docker exec ministerio-$SERVICE-1 sh -c "
    echo 'Instalando stress-ng...';
    (apk add stress-ng || apt-get update && apt-get install -y stress-ng || yum install -y stress-ng) >/dev/null 2>&1;
    
    echo 'Iniciando estresse combinado (CPU/Mem/Disco/Rede)...';
    stress-ng --cpu 4 --vm 2 --vm-bytes 512M --io 1 --hdd 1 --timeout 5m &
    stress-ng --netlink 2 --netlink-procs 4 --timeout 5m &
  " &
done

echo "[✔] Todos os containers sob ataque coordenado"
echo "Use 'pkill -f stress-ng' para encerrar emergencialmente"