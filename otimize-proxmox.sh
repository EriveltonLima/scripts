#!/bin/bash

# Script de diagnóstico e correção de performance do Proxmox
# Versão 1.0 - Interativo

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Função para exibir cabeçalho
show_header() {
    clear
    echo -e "${BLUE}${BOLD}================================================${NC}"
    echo -e "${BLUE}${BOLD}    DIAGNÓSTICO DE PERFORMANCE - PROXMOX VE     ${NC}"
    echo -e "${BLUE}${BOLD}================================================${NC}"
    echo ""
}

# Função para verificar se é root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}ERRO: Execute como root!${NC}"
        echo "Use: sudo $0"
        exit 1
    fi
}

# Função para mostrar informações do sistema
show_system_info() {
    echo -e "${CYAN}${BOLD}=== INFORMAÇÕES DO SISTEMA ===${NC}"
    echo -e "${YELLOW}Versão do Proxmox:${NC}"
    pveversion --verbose | head -5
    echo ""
    
    echo -e "${YELLOW}Hardware:${NC}"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
    echo "RAM Total: $(free -h | grep Mem | awk '{print $2}')"
    echo "RAM Livre: $(free -h | grep Mem | awk '{print $7}')"
    echo ""
    
    echo -e "${YELLOW}Uptime:${NC} $(uptime -p)"
    echo -e "${YELLOW}Load Average:${NC} $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
}

# Função para verificar I/O delay
check_io_delay() {
    echo -e "${CYAN}${BOLD}=== VERIFICAÇÃO DE I/O DELAY ===${NC}"
    
    IO_DELAY=$(cat /proc/loadavg | awk '{print $4}' | cut -d'/' -f1)
    echo -e "${YELLOW}I/O Delay atual:${NC} $IO_DELAY"
    
    if (( $(echo "$IO_DELAY > 10" | bc -l) )); then
        echo -e "${RED}⚠️  I/O Delay CRÍTICO (>10)!${NC}"
        return 1
    elif (( $(echo "$IO_DELAY > 5" | bc -l) )); then
        echo -e "${YELLOW}⚠️  I/O Delay ALTO (>5)${NC}"
        return 2
    else
        echo -e "${GREEN}✓ I/O Delay normal${NC}"
        return 0
    fi
}

# Função para verificar uso de disco
check_disk_usage() {
    echo -e "${CYAN}${BOLD}=== VERIFICAÇÃO DE ESPAÇO EM DISCO ===${NC}"
    
    df -h | grep -E "(local|pve)" | while read line; do
        usage=$(echo $line | awk '{print $5}' | sed 's/%//')
        mount=$(echo $line | awk '{print $6}')
        
        if [ "$usage" -gt 90 ]; then
            echo -e "${RED}⚠️  $mount: ${usage}% - CRÍTICO${NC}"
        elif [ "$usage" -gt 80 ]; then
            echo -e "${YELLOW}⚠️  $mount: ${usage}% - ALTO${NC}"
        else
            echo -e "${GREEN}✓ $mount: ${usage}% - OK${NC}"
        fi
    done
    echo ""
}

# Função para verificar performance de disco
test_disk_performance() {
    echo -e "${CYAN}${BOLD}=== TESTE DE PERFORMANCE DE DISCO ===${NC}"
    
    local test_file="/tmp/proxmox_disk_test.bin"
    
    echo "Testando velocidade de escrita..."
    WRITE_SPEED=$(dd if=/dev/zero of=$test_file bs=1M count=100 oflag=dsync 2>&1 | grep -o '[0-9.]\+ MB/s' | tail -1)
    
    echo "Testando velocidade de leitura..."
    sync && echo 3 > /proc/sys/vm/drop_caches
    READ_SPEED=$(dd if=$test_file of=/dev/null bs=1M 2>&1 | grep -o '[0-9.]\+ MB/s' | tail -1)
    
    rm -f $test_file
    
    echo -e "${YELLOW}Velocidade de escrita:${NC} $WRITE_SPEED"
    echo -e "${YELLOW}Velocidade de leitura:${NC} $READ_SPEED"
    
    # Extrair valor numérico para comparação
    write_val=$(echo $WRITE_SPEED | grep -o '[0-9.]\+' | head -1)
    if (( $(echo "$write_val < 50" | bc -l) )); then
        echo -e "${RED}⚠️  Performance de disco BAIXA${NC}"
        return 1
    else
        echo -e "${GREEN}✓ Performance de disco adequada${NC}"
        return 0
    fi
}

# Função para verificar VMs e containers
check_vms_containers() {
    echo -e "${CYAN}${BOLD}=== VERIFICAÇÃO DE VMs E CONTAINERS ===${NC}"
    
    echo -e "${YELLOW}VMs ativas:${NC}"
    qm list | grep running | wc -l
    
    echo -e "${YELLOW}Containers ativos:${NC}"
    pct list | grep running | wc -l
    
    echo -e "${YELLOW}Uso de CPU por VM/Container:${NC}"
    echo "ID    NAME                STATUS      CPU%    MEM%"
    echo "----------------------------------------"
    
    # VMs
    qm list | grep running | while read line; do
        vmid=$(echo $line | awk '{print $1}')
        name=$(echo $line | awk '{print $2}')
        cpu_usage=$(qm monitor $vmid info cpus 2>/dev/null | grep -o 'CPU[0-9]*.*' | head -1 || echo "N/A")
        echo "$vmid    $name    running    $cpu_usage"
    done
    
    # Containers
    pct list | grep running | while read line; do
        ctid=$(echo $line | awk '{print $1}')
        name=$(echo $line | awk '{print $3}')
        echo "$ctid    $name    running    N/A    N/A"
    done
    echo ""
}

# Função para verificar configurações de rede
check_network() {
    echo -e "${CYAN}${BOLD}=== VERIFICAÇÃO DE REDE ===${NC}"
    
    echo -e "${YELLOW}Interfaces de rede:${NC}"
    ip link show | grep -E "(vmbr|eth|ens)" | grep UP
    
    echo -e "${YELLOW}Teste de conectividade:${NC}"
    if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Conectividade externa OK${NC}"
    else
        echo -e "${RED}⚠️  Problema de conectividade externa${NC}"
    fi
    echo ""
}

# Função para otimizações automáticas
apply_optimizations() {
    echo -e "${CYAN}${BOLD}=== APLICANDO OTIMIZAÇÕES ===${NC}"
    
    echo "1. Limpando cache e logs antigos..."
    apt-get clean
    journalctl --vacuum-time=7d
    
    echo "2. Otimizando configurações de I/O..."
    echo 'vm.dirty_ratio = 5' >> /etc/sysctl.conf
    echo 'vm.dirty_background_ratio = 2' >> /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure = 50' >> /etc/sysctl.conf
    sysctl -p
    
    echo "3. Configurando scheduler de I/O..."
    for disk in $(lsblk -d -n -o NAME | grep -E "(sd|nvme)"); do
        echo mq-deadline > /sys/block/$disk/queue/scheduler 2>/dev/null || true
    done
    
    echo "4. Otimizando configurações do Proxmox..."
    # Configurar noVNC para melhor performance
    echo 'DAEMON_OPTS="--max-clients 100"' > /etc/default/novnc
    
    echo -e "${GREEN}✓ Otimizações aplicadas${NC}"
}

# Função para corrigir problemas específicos
fix_specific_issues() {
    echo -e "${CYAN}${BOLD}=== CORREÇÕES ESPECÍFICAS ===${NC}"
    
    echo "Escolha o problema a corrigir:"
    echo "1) Console noVNC lento"
    echo "2) Clonagem de VMs lenta"
    echo "3) I/O Delay alto"
    echo "4) Todas as correções"
    echo "0) Voltar"
    
    read -p "Opção: " fix_option
    
    case $fix_option in
        1)
            echo "Corrigindo console noVNC..."
            systemctl restart pveproxy
            systemctl restart pvedaemon
            echo -e "${GREEN}✓ Serviços reiniciados${NC}"
            ;;
        2)
            echo "Otimizando clonagem de VMs..."
            echo 'CLONE_OPTS="--full"' >> /etc/pve/qemu-server/clone.conf
            echo -e "${GREEN}✓ Configuração de clonagem otimizada${NC}"
            ;;
        3)
            echo "Corrigindo I/O Delay alto..."
            echo 'elevator=deadline' >> /etc/default/grub
            update-grub
            echo -e "${YELLOW}⚠️  Reinicialização necessária para aplicar${NC}"
            ;;
        4)
            apply_optimizations
            systemctl restart pveproxy pvedaemon
            echo -e "${GREEN}✓ Todas as correções aplicadas${NC}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida${NC}"
            ;;
    esac
}

# Função para gerar relatório
generate_report() {
    local report_file="/tmp/proxmox_performance_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "Gerando relatório de performance..."
    
    {
        echo "========================================="
        echo "RELATÓRIO DE PERFORMANCE - PROXMOX VE"
        echo "========================================="
        echo "Data: $(date)"
        echo ""
        
        echo "=== SISTEMA ==="
        pveversion
        echo "Uptime: $(uptime -p)"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        
        echo "=== RECURSOS ==="
        free -h
        echo ""
        df -h
        echo ""
        
        echo "=== I/O ==="
        iostat -x 1 1
        echo ""
        
        echo "=== VMs/CONTAINERS ==="
        qm list
        echo ""
        pct list
        
    } > "$report_file"
    
    echo -e "${GREEN}✓ Relatório salvo em: $report_file${NC}"
}

# Menu principal
main_menu() {
    while true; do
        show_header
        show_system_info
        
        echo -e "${CYAN}${BOLD}MENU PRINCIPAL:${NC}"
        echo "1) Verificar I/O Delay"
        echo "2) Verificar espaço em disco"
        echo "3) Testar performance de disco"
        echo "4) Verificar VMs e containers"
        echo "5) Verificar rede"
        echo "6) Aplicar otimizações automáticas"
        echo "7) Corrigir problemas específicos"
        echo "8) Gerar relatório completo"
        echo "9) Executar diagnóstico completo"
        echo "0) Sair"
        echo ""
        
        read -p "Escolha uma opção: " option
        
        case $option in
            1)
                echo ""
                check_io_delay
                read -p "Pressione Enter para continuar..."
                ;;
            2)
                echo ""
                check_disk_usage
                read -p "Pressione Enter para continuar..."
                ;;
            3)
                echo ""
                test_disk_performance
                read -p "Pressione Enter para continuar..."
                ;;
            4)
                echo ""
                check_vms_containers
                read -p "Pressione Enter para continuar..."
                ;;
            5)
                echo ""
                check_network
                read -p "Pressione Enter para continuar..."
                ;;
            6)
                echo ""
                apply_optimizations
                read -p "Pressione Enter para continuar..."
                ;;
            7)
                echo ""
                fix_specific_issues
                read -p "Pressione Enter para continuar..."
                ;;
            8)
                echo ""
                generate_report
                read -p "Pressione Enter para continuar..."
                ;;
            9)
                echo ""
                echo -e "${CYAN}${BOLD}=== DIAGNÓSTICO COMPLETO ===${NC}"
                check_io_delay
                echo ""
                check_disk_usage
                echo ""
                test_disk_performance
                echo ""
                check_vms_containers
                echo ""
                check_network
                read -p "Pressione Enter para continuar..."
                ;;
            0)
                echo -e "${GREEN}Saindo...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                read -p "Pressione Enter para continuar..."
                ;;
        esac
    done
}

# Verificar dependências
check_dependencies() {
    local deps=("bc" "iostat")
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo "Instalando dependência: $dep"
            apt-get update && apt-get install -y sysstat bc
            break
        fi
    done
}

# Programa principal
main() {
    check_root
    check_dependencies
    main_menu
}

# Executar programa principal
main
