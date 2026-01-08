#!/bin/bash

# Script para testar performance de HDD/SSD
# Uso: ./test_disk.sh /dev/sdX

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar se o dispositivo foi fornecido
if [ $# -eq 0 ]; then
    echo -e "${RED}Erro: Especifique o dispositivo a ser testado${NC}"
    echo "Uso: $0 /dev/sdX"
    echo ""
    echo "Dispositivos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -E "sd|nvme"
    exit 1
fi

DEVICE=$1
TESTFILE="/tmp/disktest_$(basename $DEVICE)_$(date +%s).bin"

# Verificar se o dispositivo existe
if [ ! -b "$DEVICE" ]; then
    echo -e "${RED}Erro: Dispositivo $DEVICE não encontrado${NC}"
    exit 1
fi

# Verificar se hdparm está instalado
if ! command -v hdparm &> /dev/null; then
    echo -e "${YELLOW}hdparm não encontrado. Instalando...${NC}"
    sudo apt-get update && sudo apt-get install -y hdparm
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    TESTE DE PERFORMANCE DE DISCO      ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Informações do dispositivo
echo -e "${GREEN}Dispositivo testado: $DEVICE${NC}"
echo ""

# Informações básicas do disco
echo -e "${YELLOW}Informações do dispositivo:${NC}"
sudo hdparm -I $DEVICE 2>/dev/null | grep -E "Model Number|Serial Number|Firmware Revision|Used: |LBA user addressable sectors"
echo ""

# Informações do sistema de arquivos
echo -e "${YELLOW}Informações do sistema de arquivos:${NC}"
df -h $DEVICE 2>/dev/null || echo "Dispositivo não montado"
echo ""

# Teste 1: hdparm - Velocidade de leitura
echo -e "${GREEN}=== TESTE 1: Velocidade de leitura (hdparm) ===${NC}"
echo "Testando cache e leitura direta do disco..."
sudo hdparm -Tt $DEVICE
echo ""

# Teste 2: dd - Velocidade de escrita
echo -e "${GREEN}=== TESTE 2: Velocidade de escrita (dd) ===${NC}"
echo "Criando arquivo de teste de 1GB..."
echo "Arquivo: $TESTFILE"

# Teste de escrita com sync
echo -e "${YELLOW}Testando velocidade de escrita...${NC}"
START_TIME=$(date +%s.%N)
sudo dd if=/dev/zero of=$TESTFILE bs=1M count=1024 oflag=dsync status=progress 2>&1
sync
END_TIME=$(date +%s.%N)

WRITE_TIME=$(echo "$END_TIME - $START_TIME" | bc)
WRITE_SPEED=$(echo "scale=2; 1024 / $WRITE_TIME" | bc)

echo ""
echo -e "${GREEN}Tempo de escrita: ${WRITE_TIME}s${NC}"
echo -e "${GREEN}Velocidade de escrita: ${WRITE_SPEED} MB/s${NC}"
echo ""

# Teste 3: dd - Velocidade de leitura
echo -e "${GREEN}=== TESTE 3: Velocidade de leitura (dd) ===${NC}"

# Limpar cache
echo -e "${YELLOW}Limpando cache do sistema...${NC}"
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# Teste de leitura
echo -e "${YELLOW}Testando velocidade de leitura...${NC}"
START_TIME=$(date +%s.%N)
sudo dd if=$TESTFILE of=/dev/null bs=1M count=1024 status=progress 2>&1
END_TIME=$(date +%s.%N)

READ_TIME=$(echo "$END_TIME - $START_TIME" | bc)
READ_SPEED=$(echo "scale=2; 1024 / $READ_TIME" | bc)

echo ""
echo -e "${GREEN}Tempo de leitura: ${READ_TIME}s${NC}"
echo -e "${GREEN}Velocidade de leitura: ${READ_SPEED} MB/s${NC}"
echo ""

# Teste 4: IOPS (Input/Output Operations Per Second)
echo -e "${GREEN}=== TESTE 4: IOPS (4K random) ===${NC}"
echo -e "${YELLOW}Testando IOPS de leitura aleatória...${NC}"

# Criar arquivo menor para teste de IOPS
sudo dd if=/dev/zero of=${TESTFILE}_iops bs=4k count=25600 2>/dev/null
sync

# Limpar cache novamente
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# Teste IOPS
START_TIME=$(date +%s.%N)
sudo dd if=${TESTFILE}_iops of=/dev/null bs=4k count=25600 iflag=direct 2>/dev/null
END_TIME=$(date +%s.%N)

IOPS_TIME=$(echo "$END_TIME - $START_TIME" | bc)
IOPS=$(echo "scale=0; 25600 / $IOPS_TIME" | bc)

echo -e "${GREEN}IOPS (4K random read): ${IOPS} ops/s${NC}"
echo ""

# Teste 5: Latência
echo -e "${GREEN}=== TESTE 5: Latência de acesso ===${NC}"
echo -e "${YELLOW}Testando latência de acesso...${NC}"

# Usar ioping se disponível, senão usar dd
if command -v ioping &> /dev/null; then
    sudo ioping -c 10 $DEVICE
else
    echo "ioping não disponível, usando método alternativo..."
    for i in {1..5}; do
        START_TIME=$(date +%s.%N)
        sudo dd if=$DEVICE of=/dev/null bs=512 count=1 iflag=direct 2>/dev/null
        END_TIME=$(date +%s.%N)
        LATENCY=$(echo "($END_TIME - $START_TIME) * 1000" | bc)
        echo "Teste $i: ${LATENCY}ms"
    done
fi
echo ""

# Resumo dos resultados
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}           RESUMO DOS RESULTADOS        ${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Dispositivo: $DEVICE${NC}"
echo -e "${GREEN}Velocidade de escrita: ${WRITE_SPEED} MB/s${NC}"
echo -e "${GREEN}Velocidade de leitura: ${READ_SPEED} MB/s${NC}"
echo -e "${GREEN}IOPS (4K random): ${IOPS} ops/s${NC}"
echo ""

# Classificação do dispositivo
if (( $(echo "$READ_SPEED > 500" | bc -l) )); then
    echo -e "${GREEN}Classificação: SSD NVMe (Alta Performance)${NC}"
elif (( $(echo "$READ_SPEED > 200" | bc -l) )); then
    echo -e "${YELLOW}Classificação: SSD SATA (Boa Performance)${NC}"
else
    echo -e "${RED}Classificação: HDD ou dispositivo lento${NC}"
fi

# Limpeza
echo ""
echo -e "${YELLOW}Removendo arquivos de teste...${NC}"
sudo rm -f $TESTFILE ${TESTFILE}_iops

echo -e "${GREEN}Teste concluído!${NC}"
