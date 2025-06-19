#!/bin/bash

# Script interativo para testar performance de HDD/SSD
# Versão melhorada com testes adicionais e verificações SMART

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
    echo -e "${BLUE}${BOLD}    Versão 2.0 - Melhorada            ${NC}"
    echo -e "${BLUE}${BOLD}========================================${NC}"
    echo ""
}

# Função para mostrar benchmarks de referência
show_benchmark_comparison() {
    echo -e "${CYAN}${BOLD}Referências de performance:${NC}"
    echo -e "${CYAN}HDD 5400 RPM:${NC} ~80 MB/s leitura, ~75 MB/s escrita, ~100 IOPS"
    echo -e "${CYAN}HDD 7200 RPM:${NC} ~120 MB/s leitura, ~110 MB/s escrita, ~150 IOPS"
    echo -e "${CYAN}SSD SATA:${NC} ~500 MB/s leitura/escrita, ~90.000 IOPS"
    echo -e "${CYAN}SSD NVMe:${NC} ~3000 MB/s leitura/escrita, ~100.000+ IOPS"
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
    
    # Verificação SMART básica
    if command -v smartctl &> /dev/null; then
        echo -e "${CYAN}Status SMART:${NC}"
        SMART_STATUS=$(sudo smartctl -H "$device" 2>/dev/null | grep -E "SMART overall-health|result")
        if [[ -n "$SMART_STATUS" ]]; then
            echo "$SMART_STATUS"
            if echo "$SMART_STATUS" | grep -q "PASSED\|OK"; then
                echo -e "${GREEN}✓ Disco aparenta estar saudável${NC}"
            else
                echo -e "${RED}⚠️ ATENÇÃO: Possíveis problemas detectados!${NC}"
            fi
        else
            echo "SMART não disponível ou não suportado"
        fi
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
    echo "• Testes em discos com problemas podem demorar muito"
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
    echo -e "${YELLOW}Verificando dependências...${NC}"
    if ! command -v hdparm &> /dev/null; then
        echo -e "${YELLOW}Instalando hdparm...${NC}"
        sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y hdparm >/dev/null 2>&1
    fi
    
    if ! command -v bc &> /dev/null; then
        echo -e "${YELLOW}Instalando bc...${NC}"
        sudo apt-get install -y bc >/dev/null 2>&1
    fi
    
    if ! command -v smartctl &> /dev/null; then
        echo -e "${YELLOW}Instalando smartmontools...${NC}"
        sudo apt-get install -y smartmontools >/dev/null 2>&1
    fi
    
    # Mostrar referências de benchmark
    show_benchmark_comparison
    
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
    
    # Teste 4: IOPS Leitura
    echo -e "${GREEN}=== TESTE 4: IOPS Leitura (4K random) ===${NC}"
    echo -e "${YELLOW}Testando IOPS de leitura aleatória...${NC}"
    
    sudo dd if=/dev/zero of="${testfile}_iops" bs=4k count=25600 2>/dev/null
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    START_TIME=$(date +%s.%N)
    sudo dd if="${testfile}_iops" of=/dev/null bs=4k count=25600 iflag=direct 2>/dev/null
    END_TIME=$(date +%s.%N)
    
    IOPS_READ_TIME=$(echo "$END_TIME - $START_TIME" | bc)
    IOPS_READ=$(echo "scale=0; 25600 / $IOPS_READ_TIME" | bc)
    
    echo -e "${GREEN}IOPS (4K random read): ${IOPS_READ} ops/s${NC}"
    echo ""
    
    # Teste 5: IOPS Escrita
    echo -e "${GREEN}=== TESTE 5: IOPS Escrita (4K random) ===${NC}"
    echo -e "${YELLOW}Testando IOPS de escrita aleatória...${NC}"
    
    START_TIME=$(date +%s.%N)
    sudo dd if=/dev/urandom of="${testfile}_write_iops" bs=4k count=10000 oflag=direct 2>/dev/null
    END_TIME=$(date +%s.%N)
    
    IOPS_WRITE_TIME=$(echo "$END_TIME - $START_TIME" | bc)
    IOPS_WRITE=$(echo "scale=0; 10000 / $IOPS_WRITE_TIME" | bc)
    
    echo -e "${GREEN}IOPS (4K random write): ${IOPS_WRITE} ops/s${NC}"
    echo ""

    # Teste 6: Latência de acesso
    echo -e "${GREEN}=== TESTE 6: Latência de acesso ===${NC}"
    echo -e "${YELLOW}Testando latência de acesso...${NC}"

    if command -v ioping &> /dev/null; then
        sudo ioping -c 10 "$device"
    else
        echo "ioping não disponível, usando método alternativo..."
        TOTAL_LATENCY=0
        for i in {1..5}; do
            START_TIME=$(date +%s.%N)
            sudo dd if="$device" of=/dev/null bs=512 count=1 iflag=direct 2>/dev/null
            END_TIME=$(date +%s.%N)
            LATENCY=$(echo "($END_TIME - $START_TIME) * 1000" | bc)
            echo "Teste $i: ${LATENCY}ms"
            TOTAL_LATENCY=$(echo "$TOTAL_LATENCY + $LATENCY" | bc)
        done
        AVG_LATENCY=$(echo "scale=2; $TOTAL_LATENCY / 5" | bc)
        echo -e "${GREEN}Latência média: ${AVG_LATENCY}ms${NC}"
    fi
    echo ""

    # Teste 7: Verificação SMART detalhada
    if command -v smartctl &> /dev/null; then
        echo -e "${GREEN}=== TESTE 7: Análise SMART detalhada ===${NC}"
        echo -e "${YELLOW}Coletando dados SMART...${NC}"
        
        # Status geral
        SMART_HEALTH=$(sudo smartctl -H "$device" 2>/dev/null | grep -E "SMART overall-health|result")
        echo -e "${CYAN}Status geral:${NC} $SMART_HEALTH"
        
        # Temperatura
        TEMP=$(sudo smartctl -A "$device" 2>/dev/null | grep -i temperature | head -1 | awk '{print $10}')
        if [[ -n "$TEMP" && "$TEMP" =~ ^[0-9]+$ ]]; then
            echo -e "${CYAN}Temperatura:${NC} ${TEMP}°C"
        fi
        
        # Horas de uso
        POWER_ON=$(sudo smartctl -A "$device" 2>/dev/null | grep "Power_On_Hours" | awk '{print $10}')
        if [[ -n "$POWER_ON" && "$POWER_ON" =~ ^[0-9]+$ ]]; then
            DAYS=$(echo "scale=1; $POWER_ON / 24" | bc)
            echo -e "${CYAN}Horas ligado:${NC} ${POWER_ON}h (${DAYS} dias)"
        fi
        
        # Contagem de start/stop
        START_STOP=$(sudo smartctl -A "$device" 2>/dev/null | grep "Start_Stop_Count" | awk '{print $10}')
        if [[ -n "$START_STOP" ]]; then
            echo -e "${CYAN}Ciclos liga/desliga:${NC} ${START_STOP}"
        fi
        
        echo ""
    fi

    # Resumo dos resultados
    echo -e "${BLUE}${BOLD}========================================${NC}"
    echo -e "${BLUE}${BOLD}           RESUMO DOS RESULTADOS        ${NC}"
    echo -e "${BLUE}${BOLD}========================================${NC}"
    echo -e "${GREEN}Dispositivo: $device${NC}"
    echo -e "${GREEN}Velocidade de escrita: ${WRITE_SPEED} MB/s${NC}"
    echo -e "${GREEN}Velocidade de leitura: ${READ_SPEED} MB/s${NC}"
    echo -e "${GREEN}IOPS leitura (4K): ${IOPS_READ} ops/s${NC}"
    echo -e "${GREEN}IOPS escrita (4K): ${IOPS_WRITE} ops/s${NC}"
    echo ""

    # Classificação melhorada do dispositivo
    if (( $(echo "$READ_SPEED > 2000" | bc -l) )); then
        echo -e "${GREEN}${BOLD}Classificação: SSD NVMe PCIe 4.0 (Performance Extrema)${NC}"
    elif (( $(echo "$READ_SPEED > 500" | bc -l) )); then
        echo -e "${GREEN}${BOLD}Classificação: SSD NVMe PCIe 3.0 (Alta Performance)${NC}"
    elif (( $(echo "$READ_SPEED > 200" | bc -l) )); then
        echo -e "${YELLOW}${BOLD}Classificação: SSD SATA (Boa Performance)${NC}"
    elif (( $(echo "$READ_SPEED > 80" | bc -l) )); then
        echo -e "${YELLOW}${BOLD}Classificação: HDD 7200 RPM (Performance Normal)${NC}"
    elif (( $(echo "$READ_SPEED > 50" | bc -l) )); then
        echo -e "${RED}${BOLD}Classificação: HDD 5400 RPM (Performance Baixa)${NC}"
    else
        echo -e "${RED}${BOLD}Classificação: Dispositivo com problemas (Performance Crítica)${NC}"
        echo -e "${RED}⚠️  RECOMENDAÇÃO: Faça backup imediato e substitua o disco!${NC}"
    fi

    # Análise de saúde baseada nos resultados
    echo ""
    echo -e "${CYAN}${BOLD}Análise de saúde:${NC}"
    
    if (( $(echo "$WRITE_SPEED < 10" | bc -l) )); then
        echo -e "${RED}• Velocidade de escrita crítica - possível falha iminente${NC}"
    elif (( $(echo "$WRITE_SPEED < 50" | bc -l) )); then
        echo -e "${YELLOW}• Velocidade de escrita baixa - monitore o disco${NC}"
    else
        echo -e "${GREEN}• Velocidade de escrita normal${NC}"
    fi
    
    if (( $(echo "$IOPS_READ < 100" | bc -l) )); then
        echo -e "${RED}• IOPS muito baixo - disco com problemas${NC}"
    elif (( $(echo "$IOPS_READ < 1000" | bc -l) )); then
        echo -e "${YELLOW}• IOPS baixo - típico de HDD${NC}"
    else
        echo -e "${GREEN}• IOPS adequado${NC}"
    fi

    # Limpeza
    echo ""
    echo -e "${YELLOW}Removendo arquivos de teste...${NC}"
    sudo rm -f "$testfile" "${testfile}_iops" "${testfile}_write_iops"
    
    # Oferecer salvar resultados
    echo ""
    save_results "$device" "$WRITE_SPEED" "$READ_SPEED" "$IOPS_READ" "$IOPS_WRITE"
    
    echo -e "${GREEN}${BOLD}Teste concluído!${NC}"
}

# Função para salvar resultados
save_results() {
    local device=$1
    local write_speed=$2
    local read_speed=$3
    local iops_read=$4
    local iops_write=$5
    
    local logfile="disk_test_$(basename $device)_$(date +%Y%m%d_%H%M%S).log"
    
    read -p "Deseja salvar os resultados em arquivo? (s/n): " save_choice
    
    if [[ $save_choice =~ ^[Ss]$ ]]; then
        {
            echo "========================================="
            echo "TESTE DE PERFORMANCE DE DISCO"
            echo "Versão 2.0 - Melhorada"
            echo "========================================="
            echo "Data/Hora: $(date)"
            echo "Dispositivo: $device"
            echo "Velocidade de escrita: ${write_speed} MB/s"
            echo "Velocidade de leitura: ${read_speed} MB/s"
            echo "IOPS leitura (4K): ${iops_read} ops/s"
            echo "IOPS escrita (4K): ${iops_write} ops/s"
            echo ""
            echo "Informações do sistema:"
            echo "Kernel: $(uname -r)"
            echo "Distribuição: $(lsb_release -d 2>/dev/null | cut -f2 || echo "N/A")"
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
