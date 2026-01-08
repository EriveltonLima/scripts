#!/bin/bash

# Script para gerenciar IPs de containers LXC no Proxmox
# Com verificação de IPs existentes

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configurações padrão
DEFAULT_BASE_IP="192.168.8"
DEFAULT_START_IP=253
DEFAULT_GATEWAY="192.168.8.1"
DEFAULT_BRIDGE="vmbr0"
DEFAULT_NETMASK="24"

# Função para obter IP atual de um container
get_container_ip() {
    local ct_id=$1
    local current_ip=""
    
    # Tentar obter IP da configuração
    local net_config=$(pct config $ct_id 2>/dev/null | grep "^net0:")
    if [[ -n "$net_config" ]]; then
        current_ip=$(echo "$net_config" | grep -o "ip=[^,]*" | cut -d= -f2 | cut -d/ -f1 2>/dev/null)
    fi
    
    # Se não encontrou na config, tentar obter do container em execução
    if [[ -z "$current_ip" ]] && pct status $ct_id 2>/dev/null | grep -q "running"; then
        current_ip=$(pct exec $ct_id -- hostname -I 2>/dev/null | awk '{print $1}' | head -1)
    fi
    
    echo "$current_ip"
}

# Função para verificar se IP está na faixa desejada
is_ip_in_range() {
    local ip=$1
    local base_ip=$2
    local start_ip=$3
    local end_ip=${4:-1}
    
    if [[ -z "$ip" ]]; then
        return 1
    fi
    
    # Extrair último octeto
    local last_octet=$(echo "$ip" | cut -d. -f4)
    local ip_base=$(echo "$ip" | cut -d. -f1-3)
    
    # Verificar se está na base correta e na faixa
    if [[ "$ip_base" == "$base_ip" ]] && [[ "$last_octet" -ge "$end_ip" ]] && [[ "$last_octet" -le "$start_ip" ]]; then
        return 0
    else
        return 1
    fi
}

# Função para listar containers e seus IPs atuais
list_containers_with_ips() {
    echo -e "${BLUE}=== Containers e seus IPs atuais ===${NC}"
    echo
    
    containers=$(pct list | awk 'NR>1 {print $1}')
    
    if [ -z "$containers" ]; then
        echo -e "${RED}Nenhum container encontrado!${NC}"
        return 1
    fi
    
    printf "%-8s %-25s %-15s %-10s %-15s\n" "ID" "Nome" "IP Atual" "Status" "Faixa OK?"
    echo "--------------------------------------------------------------------------------"
    
    for ct in $containers; do
        local ct_name=$(pct config $ct 2>/dev/null | grep "^hostname:" | cut -d' ' -f2 2>/dev/null || echo "sem-nome")
        local current_ip=$(get_container_ip $ct)
        local status=$(pct status $ct 2>/dev/null | awk '{print $2}' || echo "erro")
        local in_range="NÃO"
        
        if is_ip_in_range "$current_ip" "$DEFAULT_BASE_IP" "$DEFAULT_START_IP" 1; then
            in_range="SIM"
        fi
        
        # Truncar nome se muito longo
        if [[ ${#ct_name} -gt 24 ]]; then
            ct_name="${ct_name:0:21}..."
        fi
        
        printf "%-8s %-25s %-15s %-10s %-15s\n" "$ct" "$ct_name" "${current_ip:-"sem-ip"}" "$status" "$in_range"
    done
    
    echo
}

# Função para configurar IPs reversos com verificação
configure_reverse_ips_smart() {
    echo -e "${BLUE}Configurando IPs reversos com verificação inteligente...${NC}"
    echo
    
    # Solicitar configurações
    read -p "Base IP (padrão: $DEFAULT_BASE_IP): " base_ip
    base_ip=${base_ip:-$DEFAULT_BASE_IP}
    
    read -p "IP inicial (padrão: $DEFAULT_START_IP): " start_ip
    start_ip=${start_ip:-$DEFAULT_START_IP}
    
    read -p "Gateway (padrão: $DEFAULT_GATEWAY): " gateway
    gateway=${gateway:-$DEFAULT_GATEWAY}
    
    read -p "Bridge (padrão: $DEFAULT_BRIDGE): " bridge
    bridge=${bridge:-$DEFAULT_BRIDGE}
    
    echo
    echo -e "${YELLOW}Configuração de rede:${NC}"
    echo "  - Rede base: $base_ip.0/$DEFAULT_NETMASK"
    echo "  - IP inicial: $base_ip.$start_ip"
    echo "  - Gateway: $gateway"
    echo "  - Bridge: $bridge"
    echo
    
    containers=$(pct list | awk 'NR>1 {print $1}')
    
    if [ -z "$containers" ]; then
        echo -e "${RED}Nenhum container encontrado!${NC}"
        return 1
    fi
    
    # Analisar situação atual
    echo -e "${CYAN}=== Análise da situação atual ===${NC}"
    local containers_to_change=()
    local containers_ok=()
    local current_ip=$start_ip
    
    for ct in $containers; do
        local ct_name=$(pct config $ct 2>/dev/null | grep "^hostname:" | cut -d' ' -f2 2>/dev/null || echo "container-$ct")
        local existing_ip=$(get_container_ip $ct)
        local target_ip="$base_ip.$current_ip"
        
        if [[ "$existing_ip" == "$target_ip" ]]; then
            containers_ok+=("$ct:$ct_name:$existing_ip")
            echo -e "${GREEN}✓ Container $ct ($ct_name) já tem IP correto: $existing_ip${NC}"
        else
            containers_to_change+=("$ct:$ct_name:$existing_ip:$target_ip")
            if [[ -n "$existing_ip" ]]; then
                echo -e "${YELLOW}⚠ Container $ct ($ct_name) precisa mudar: $existing_ip → $target_ip${NC}"
            else
                echo -e "${YELLOW}⚠ Container $ct ($ct_name) sem IP → $target_ip${NC}"
            fi
        fi
        
        current_ip=$((current_ip - 1))
        
        if [ $current_ip -lt 1 ]; then
            echo -e "${RED}⚠ Limite de IPs atingido! Containers restantes não serão processados.${NC}"
            break
        fi
    done
    
    echo
    echo -e "${CYAN}=== Resumo ===${NC}"
    echo "Containers que já estão corretos: ${#containers_ok[@]}"
    echo "Containers que precisam de alteração: ${#containers_to_change[@]}"
    echo
    
    if [ ${#containers_to_change[@]} -eq 0 ]; then
        echo -e "${GREEN}Todos os containers já estão com IPs corretos!${NC}"
        return 0
    fi
    
    # Mostrar containers que serão alterados
    echo -e "${YELLOW}Containers que serão alterados:${NC}"
    for entry in "${containers_to_change[@]}"; do
        IFS=':' read -r ct_id ct_name old_ip new_ip <<< "$entry"
        echo "  - Container $ct_id ($ct_name): ${old_ip:-"sem-ip"} → $new_ip"
    done
    echo
    
    read -p "Deseja continuar com as alterações? (s/N): " confirm
    if [[ ! $confirm =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Operação cancelada.${NC}"
        return 0
    fi
    
    # Aplicar alterações
    echo
    echo -e "${BLUE}Aplicando alterações...${NC}"
    
    for entry in "${containers_to_change[@]}"; do
        IFS=':' read -r ct_id ct_name old_ip new_ip <<< "$entry"
        
        echo -e "${CYAN}Configurando container $ct_id ($ct_name)...${NC}"
        
        # Verificar se container está travado
        if pct status $ct_id 2>/dev/null | grep -q "locked"; then
            echo -e "${RED}  ✗ Container $ct_id está travado, pulando...${NC}"
            continue
        fi
        
        # Verificar status do container
        local container_status=$(pct status $ct_id 2>/dev/null | awk '{print $2}')
        local was_running=false
        
        if [ "$container_status" = "running" ]; then
            echo "  Parando container $ct_id..."
            pct stop $ct_id
            was_running=true
            sleep 2
        fi
        
        # Aplicar nova configuração de rede
        pct set $ct_id --net0 name=eth0,bridge=$bridge,ip=$new_ip/$DEFAULT_NETMASK,gw=$gateway
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✓ IP configurado: $new_ip${NC}"
            
            # Reiniciar container se estava rodando
            if [ "$was_running" = true ]; then
                echo "  Reiniciando container $ct_id..."
                pct start $ct_id
                sleep 3
                
                # Verificar se o IP foi aplicado corretamente
                local new_actual_ip=$(get_container_ip $ct_id)
                if [[ "$new_actual_ip" == "$new_ip" ]]; then
                    echo -e "${GREEN}  ✓ IP verificado e funcionando: $new_actual_ip${NC}"
                else
                    echo -e "${YELLOW}  ⚠ IP configurado mas verificação falhou (pode levar alguns segundos)${NC}"
                fi
            fi
        else
            echo -e "${RED}  ✗ Erro ao configurar IP para container $ct_id${NC}"
        fi
        
        echo
    done
    
    echo -e "${GREEN}Configuração de IPs concluída!${NC}"
}

# Função para verificar conflitos de IP
check_ip_conflicts() {
    echo -e "${BLUE}Verificando conflitos de IP...${NC}"
    echo
    
    containers=$(pct list | awk 'NR>1 {print $1}')
    declare -A ip_map
    local conflicts_found=false
    
    # Mapear IPs
    for ct in $containers; do
        local current_ip=$(get_container_ip $ct)
        if [[ -n "$current_ip" ]]; then
            if [[ -n "${ip_map[$current_ip]}" ]]; then
                echo -e "${RED}⚠ CONFLITO: IP $current_ip usado por containers ${ip_map[$current_ip]} e $ct${NC}"
                conflicts_found=true
            else
                ip_map[$current_ip]=$ct
            fi
        fi
    done
    
    if [ "$conflicts_found" = false ]; then
        echo -e "${GREEN}✓ Nenhum conflito de IP encontrado${NC}"
    fi
    
    echo
}

# Função para corrigir IPs específicos
fix_specific_containers() {
    echo -e "${BLUE}Correção de containers específicos...${NC}"
    echo
    
    list_containers_with_ips
    
    read -p "Digite os IDs dos containers para corrigir (separados por espaço): " container_ids
    
    if [[ -z "$container_ids" ]]; then
        echo -e "${YELLOW}Nenhum container selecionado.${NC}"
        return 0
    fi
    
    # Solicitar configurações
    read -p "Base IP (padrão: $DEFAULT_BASE_IP): " base_ip
    base_ip=${base_ip:-$DEFAULT_BASE_IP}
    
    read -p "IP inicial para o primeiro container: " start_ip
    if [[ -z "$start_ip" ]]; then
        echo -e "${RED}IP inicial é obrigatório!${NC}"
        return 1
    fi
    
    read -p "Gateway (padrão: $DEFAULT_GATEWAY): " gateway
    gateway=${gateway:-$DEFAULT_GATEWAY}
    
    read -p "Bridge (padrão: $DEFAULT_BRIDGE): " bridge
    bridge=${bridge:-$DEFAULT_BRIDGE}
    
    echo
    local current_ip=$start_ip
    
    for ct_id in $container_ids; do
        if ! pct status $ct_id &>/dev/null; then
            echo -e "${RED}Container $ct_id não existe, pulando...${NC}"
            continue
        fi
        
        local target_ip="$base_ip.$current_ip"
        local ct_name=$(pct config $ct_id 2>/dev/null | grep "^hostname:" | cut -d' ' -f2 2>/dev/null || echo "container-$ct_id")
        
        echo -e "${CYAN}Configurando container $ct_id ($ct_name) com IP $target_ip...${NC}"
        
        # Aplicar configuração
        local container_status=$(pct status $ct_id 2>/dev/null | awk '{print $2}')
        local was_running=false
        
        if [ "$container_status" = "running" ]; then
            pct stop $ct_id
            was_running=true
            sleep 2
        fi
        
        pct set $ct_id --net0 name=eth0,bridge=$bridge,ip=$target_ip/$DEFAULT_NETMASK,gw=$gateway
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Container $ct_id configurado com IP $target_ip${NC}"
            
            if [ "$was_running" = true ]; then
                pct start $ct_id
                sleep 2
            fi
        else
            echo -e "${RED}✗ Erro ao configurar container $ct_id${NC}"
        fi
        
        current_ip=$((current_ip - 1))
        echo
    done
}

# Menu principal
show_menu() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}    Gerenciador de IPs - Containers LXC${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo
    echo -e "${GREEN}1.${NC} Listar containers e IPs atuais"
    echo -e "${GREEN}2.${NC} Configurar IPs reversos (com verificação)"
    echo -e "${GREEN}3.${NC} Verificar conflitos de IP"
    echo -e "${GREEN}4.${NC} Corrigir containers específicos"
    echo -e "${GREEN}5.${NC} Sair"
    echo
    echo -n -e "${YELLOW}Escolha uma opção [1-5]: ${NC}"
}

# Função principal
main() {
    # Verificar se está rodando como root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Este script deve ser executado como root!${NC}"
        exit 1
    fi
    
    # Verificar se o pct está disponível
    if ! command -v pct &> /dev/null; then
        echo -e "${RED}Comando 'pct' não encontrado! Certifique-se de estar rodando no Proxmox VE.${NC}"
        exit 1
    fi
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                echo
                list_containers_with_ips
                echo
                read -p "Pressione Enter para continuar..."
                ;;
            2)
                echo
                configure_reverse_ips_smart
                echo
                read -p "Pressione Enter para continuar..."
                ;;
            3)
                echo
                check_ip_conflicts
                echo
                read -p "Pressione Enter para continuar..."
                ;;
            4)
                echo
                fix_specific_containers
                echo
                read -p "Pressione Enter para continuar..."
                ;;
            5)
                echo -e "${GREEN}Saindo...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida! Pressione Enter para tentar novamente...${NC}"
                read
                ;;
        esac
    done
}

# Executar o script
main
