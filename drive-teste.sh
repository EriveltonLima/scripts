#!/bin/bash

# Script interativo para testar performance de HDD/SSD
# Versão interativa com seleção de disco

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Função para exibir cabeçalho
show_header() {
    clear
    echo -e "${BLUE}${BOLD}========================================${NC}"
    echo -e "${BLUE}${BOLD}    TESTE DE PERFORMANCE DE DISCO      ${NC}"
    echo -e "${BLUE}${BOLD}========================================${NC}"
    echo ""
}

# Função para listar discos disponíveis
list_disks() {
    echo -e "${CYAN}${BOLD}Discos disponíveis no sistema:${NC}"
    echo ""
    
    # Array para armazenar dispositivos
    DEVICES=()
    COUNTER=1
    
    # Listar dispositivos de bloco (excluindo partições e loops)
    while IFS= read -r line; do
        DEVICE=$(echo "$line" | awk '{print $1}')
        SIZE=$(echo "$line" | awk '{print $4}')
        MODEL=$(echo "$line" | awk '{for(i=5;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')
        TYPE=$(echo "$line" | awk '{print $6}')
        
        # Filtrar apenas discos físicos
        if [[ "$TYPE" == "disk" ]]; then
            DEVICES+=("/dev/$DEVICE")
            printf "${GREEN}%2d)${NC} %-12s ${YELLOW}%-8s${NC} %s\n" "$COUNTER" "/dev/$DEVICE" "$SIZE" "$MODEL"
            ((COUNTER++))
        fi
    done < <(lsblk -d -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,MODEL | grep -v "NAME" | grep -E "sd|nvme|hd")
    
    echo ""
    
    # Verificar se encontrou dispositivos
    if [ ${#DEVICES[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum disco encontrado!${NC}"
        exit 1
    fi
}

# Função para mostrar informações detalhadas do disco
show_disk_info() {
    local device=$1
    
    echo -e "${YELLOW}${BOLD}Informações detalhadas do dispositivo: $device${NC}"
    echo ""
    
    # Informações básicas
    echo -e "${CYAN}Informações gerais:${NC}"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT "$device" 2>/dev/null
    echo ""
    
    # Informações técnicas com hdparm
    if command -v hdparm &> /dev/null; then
        echo -e "${CYAN}Informações técnicas:${NC}"
        sudo hdparm -I "$device" 2>/dev/null | grep -E "Model Number|Serial Number|Firmware Revision|Transport:|Interface:" | head -5
        echo ""
    fi
    
    # Verificar se está montado
    if mount | grep -q "$device"; then
        echo -e "${YELLOW}⚠️  ATENÇÃO: Este disco possui partições montadas!${NC}"
        echo -e "${YELLOW}   Partições montadas:${NC}"
        mount | grep "$device" | awk '{print "   " $1 " -> " $3}'
        echo ""
    fi
}

# Função para confirmar teste
confirm_test() {
    local device=$1
    
    echo -e "${YELLOW}${BOLD}Você está prestes a testar: $device${NC}"
    echo ""
    echo -e "${RED}IMPORTANTE:${NC}"
    echo "• O teste criará arquivos temporários de até 1GB"
    echo "• O teste pode demorar alguns minutos"
    echo "• Certifique-se de ter espaço livre suficiente"
    echo ""
    
    while true; do
        read -p "Deseja continuar com o teste? (s/n): " yn
        case $yn in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor, responda 's' para sim ou 'n' para não.";;
        esac
    done
}

# Função principal de teste
run_disk_test() {
    local device=$1
    local testfile="/tmp/disktest_$(basename $device)_$(date +%s).bin"
    
    echo -e "${GREEN}${BOLD}Iniciando teste de performance...${NC}"
    echo ""
    
    # Verificar dependências
    if ! command -v hdparm &> /dev/null; then
        echo -e "${YELLOW}Instalando hdparm...${NC}"
        sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y hdparm >/dev/null 2>&1
    fi
    
    if ! command -v bc &> /dev/null; then
        echo -e "${YELLOW}Instalando bc...${NC}"
        sudo apt-get install -y bc >/dev/null 2>&1
    fi
    
    # Teste 1: hdparm - Velocidade de leitura
    echo -e "${GREEN}=== TESTE 1: Velocidade de leitura (hdparm) ===${NC}"
    echo "Testando cache e leitura direta do disco..."
    sudo hdparm -Tt "$device"
    echo ""
    
    # Teste 2: dd - Velocidade de escrita
    echo -e "${GREEN}=== TESTE 2: Velocidade de escrita (dd) ===${NC}"
    echo "Criando arquivo de teste de 1GB..."
    echo "Arquivo: $testfile"
    
    echo -e "${YELLOW}Testando velocidade de escrita...${NC}"
    START_TIME=$(date +%s.%N)
    sudo dd if=/dev/zero of="$testfile" bs=1M count=1024 oflag=dsync status=progress 2>&1
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
    
    echo -e "${YELLOW}Limpando cache do sistema...${NC}"
    sudo sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    echo -e "${YELLOW}Testando velocidade de leitura...${NC}"
    START_TIME=$(date +%s.%N)
    sudo dd if="$testfile" of=/dev/null bs=1M count=1024 status=progress 2>&1
    END_TIME=$(date +%s.%N)
    
    READ_TIME=$(echo "$END_TIME - $START_TIME" | bc)
    READ_SPEED=$(echo "scale=2; 1024 / $READ_TIME" | bc)
    
    echo ""
    echo -e "${GREEN}Tempo de leitura: ${READ_TIME}s${NC}"
    echo -e "${GREEN}Velocidade de leitura: ${READ_SPEED} MB/s${NC}"
    echo ""
    
    # Teste 4: IOPS
    echo -e "${GREEN}=== TESTE 4: IOPS (4K random) ===${NC}"
    echo -e "${YELLOW}Testando IOPS de leitura aleatória...${NC}"
    
    sudo dd if=/dev/zero of="${testfile}_iops" bs=4k count=25600 2>/dev/null
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    START_TIME=$(date +%s.%N)
    sudo dd if="${testfile}_iops" of=/dev/null bs=4k count=25600 iflag=direct 2>/dev/null
    END_TIME=$(date +%s.%N)
    
    IOPS_TIME=$(echo "$END_TIME - $START_TIME" | bc)
    IOPS=$(echo "scale=0; 25600 / $IOPS_TIME" | bc)
    
    echo -e "${GREEN}IOPS (4K random read): ${IOPS} ops/s${NC}"
    echo ""
    
    # Resumo dos resultados
    echo -e "${BLUE}${BOLD}========================================${NC}"
    echo -e "${BLUE}${BOLD}           RESUMO DOS RESULTADOS        ${NC}"
    echo -e "${BLUE}${BOLD}========================================${NC}"
    echo -e "${GREEN}Dispositivo: $device${NC}"
    echo -e "${GREEN}Velocidade de escrita: ${WRITE_SPEED} MB/s${NC}"
    echo -e "${GREEN}Velocidade de leitura: ${READ_SPEED} MB/s${NC}"
    echo -e "${GREEN}IOPS (4K random): ${IOPS} ops/s${NC}"
    echo ""
    
    # Classificação do dispositivo
    if (( $(echo "$READ_SPEED > 500" | bc -l) )); then
        echo -e "${GREEN}${BOLD}Classificação: SSD NVMe (Alta Performance)${NC}"
    elif (( $(echo "$READ_SPEED > 200" | bc -l) )); then
        echo -e "${YELLOW}${BOLD}Classificação: SSD SATA (Boa Performance)${NC}"
    else
        echo -e "${RED}${BOLD}Classificação: HDD ou dispositivo lento${NC}"
    fi
    
    # Limpeza
    echo ""
    echo -e "${YELLOW}Removendo arquivos de teste...${NC}"
    sudo rm -f "$testfile" "${testfile}_iops"
    
    echo -e "${GREEN}${BOLD}Teste concluído!${NC}"
}

# Função para salvar resultados
save_results() {
    local device=$1
    local write_speed=$2
    local read_speed=$3
    local iops=$4
    
    local logfile="disk_test_$(basename $device)_$(date +%Y%m%d_%H%M%S).log"
    
    echo "Deseja salvar os resultados em arquivo? (s/n): "
    read -r save_choice
    
    if [[ $save_choice =~ ^[Ss]$ ]]; then
        {
            echo "========================================="
            echo "TESTE DE PERFORMANCE DE DISCO"
            echo "========================================="
            echo "Data/Hora: $(date)"
            echo "Dispositivo: $device"
            echo "Velocidade de escrita: ${write_speed} MB/s"
            echo "Velocidade de leitura: ${read_speed} MB/s"
            echo "IOPS (4K random): ${iops} ops/s"
            echo "========================================="
        } > "$logfile"
        
        echo -e "${GREEN}Resultados salvos em: $logfile${NC}"
    fi
}

# Função principal
main() {
    show_header
    
    # Verificar se está rodando como root para alguns comandos
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Nota: Alguns comandos podem solicitar senha de sudo${NC}"
        echo ""
    fi
    
    while true; do
        list_disks
        
        echo -e "${CYAN}${BOLD}Escolha uma opção:${NC}"
        echo "0) Sair"
        echo ""
        
        read -p "Digite o número do disco a ser testado: " choice
        
        # Verificar se é número válido
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Opção inválida! Digite apenas números.${NC}"
            read -p "Pressione Enter para continuar..."
            show_header
            continue
        fi
        
        # Opção sair
        if [ "$choice" -eq 0 ]; then
            echo -e "${GREEN}Saindo...${NC}"
            exit 0
        fi
        
        # Verificar se a escolha está no range
        if [ "$choice" -lt 1 ] || [ "$choice" -gt ${#DEVICES[@]} ]; then
            echo -e "${RED}Opção inválida! Escolha entre 1 e ${#DEVICES[@]}.${NC}"
            read -p "Pressione Enter para continuar..."
            show_header
            continue
        fi
        
        # Obter dispositivo selecionado
        SELECTED_DEVICE=${DEVICES[$((choice-1))]}
        
        echo ""
        show_disk_info "$SELECTED_DEVICE"
        
        if confirm_test "$SELECTED_DEVICE"; then
            echo ""
            run_disk_test "$SELECTED_DEVICE"
            echo ""
            read -p "Pressione Enter para continuar..."
        fi
        
        show_header
    done
}

# Executar função principal
main
