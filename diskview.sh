#!/bin/bash

# DiskView Ultra - Versão Corrigida com Navegação Funcional
# Correção dos problemas de navegação e entrada automática
# Versão: 2.1

set -e

# Cores para interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'

# Caracteres especiais
BLOCK_FULL="█"
BLOCK_EMPTY="░"
ARROW="►"
BULLET="●"

# Variáveis globais
declare -a FILESYSTEMS
declare -a SIZES
declare -a USED
declare -a AVAILABLE
declare -a PERCENTAGES
declare -a MOUNTPOINTS
declare -a TYPES
SELECTED=0
AUTO_REFRESH=false
REFRESH_INTERVAL=3

# Função para configurar terminal para navegação
setup_terminal() {
    # Configurar terminal para capturar teclas especiais
    stty -echo -icanon min 1 time 0
}

# Função para restaurar terminal
restore_terminal() {
    stty echo icanon
}

# Função para ler tecla única
read_key() {
    local key
    IFS= read -r -n1 key 2>/dev/null
    
    # Verificar se é sequência de escape (setas)
    if [[ $key == $'\x1b' ]]; then
        IFS= read -r -n1 key 2>/dev/null
        if [[ $key == '[' ]]; then
            IFS= read -r -n1 key 2>/dev/null
            case $key in
                'A') echo "UP" ;;
                'B') echo "DOWN" ;;
                'C') echo "RIGHT" ;;
                'D') echo "LEFT" ;;
                *) echo "ESC" ;;
            esac
        else
            echo "ESC"
        fi
    else
        case $key in
            '') echo "ENTER" ;;
            ' ') echo "SPACE" ;;
            $'\x7f') echo "BACKSPACE" ;;
            $'\x03') echo "CTRL_C" ;;
            *) echo "$key" ;;
        esac
    fi
}

# Função para obter dados do df
get_disk_data() {
    FILESYSTEMS=()
    SIZES=()
    USED=()
    AVAILABLE=()
    PERCENTAGES=()
    MOUNTPOINTS=()
    TYPES=()
    
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^Filesystem ]] && continue
        
        local fields=($line)
        local filesystem="${fields[0]}"
        local fstype="${fields[1]}"
        local size="${fields[2]}"
        local used="${fields[3]}"
        local avail="${fields[4]}"
        local percent="${fields[5]%?}"
        local mountpoint="${fields[6]}"
        
        if [[ ! "$filesystem" =~ ^(tmpfs|udev|devpts|sysfs|proc|cgroup)$ ]] && [[ "$size" != "0" ]]; then
            FILESYSTEMS+=("$filesystem")
            TYPES+=("$fstype")
            SIZES+=("$size")
            USED+=("$used")
            AVAILABLE+=("$avail")
            PERCENTAGES+=("$percent")
            MOUNTPOINTS+=("$mountpoint")
        fi
    done < <(df -hT 2>/dev/null)
}

# Função para criar barra visual
create_bar() {
    local percentage=$1
    local width=40
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    local bar=""
    local color=""
    
    if [ $percentage -ge 90 ]; then
        color=$RED
    elif [ $percentage -ge 75 ]; then
        color=$YELLOW
    elif [ $percentage -ge 50 ]; then
        color=$BLUE
    else
        color=$GREEN
    fi
    
    for ((i=0; i<filled; i++)); do
        bar+="${color}${BLOCK_FULL}${NC}"
    done
    
    for ((i=0; i<empty; i++)); do
        bar+="${GRAY}${BLOCK_EMPTY}${NC}"
    done
    
    echo -e "$bar"
}

# Função para truncar texto
truncate_text() {
    local text="$1"
    local max_length=$2
    
    if [ ${#text} -gt $max_length ]; then
        echo "${text:0:$((max_length-3))}..."
    else
        printf "%-${max_length}s" "$text"
    fi
}

# Função para desenhar interface principal
draw_interface() {
    clear
    
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                                    DISKVIEW ULTRA                                                   ${WHITE}║${NC}"
    echo -e "${WHITE}║${YELLOW}                          Visualizador Interativo de Espaço em Disco                             ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    
    if [ ${#FILESYSTEMS[@]} -eq 0 ]; then
        echo -e "${WHITE}║${NC} ${RED}Nenhum sistema de arquivos encontrado!${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        return
    fi
    
    # Status geral
    local total_disks=${#FILESYSTEMS[@]}
    local critical_disks=0
    local warning_disks=0
    local healthy_disks=0
    
    for percent in "${PERCENTAGES[@]}"; do
        if [ $percent -ge 90 ]; then
            critical_disks=$((critical_disks + 1))
        elif [ $percent -ge 75 ]; then
            warning_disks=$((warning_disks + 1))
        else
            healthy_disks=$((healthy_disks + 1))
        fi
    done
    
    echo -e "${WHITE}║${NC} ${BOLD}Status:${NC} ${GREEN}●${NC} Saudáveis: ${GREEN}$healthy_disks${NC} | ${YELLOW}●${NC} Atenção: ${YELLOW}$warning_disks${NC} | ${RED}●${NC} Críticos: ${RED}$critical_disks${NC} | Total: ${CYAN}$total_disks${NC}"
    
    if [ "$AUTO_REFRESH" = true ]; then
        echo -e "${WHITE}║${NC} ${GREEN}🔄 Auto-refresh: ATIVO${NC} (${REFRESH_INTERVAL}s) | Atualização: $(date '+%H:%M:%S')"
    else
        echo -e "${WHITE}║${NC} ${GRAY}🔄 Auto-refresh: INATIVO${NC} | Última atualização: $(date '+%H:%M:%S')"
    fi
    
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}St${NC} ${BOLD}Sistema de Arquivos (Caminho Completo)${NC}           ${BOLD}Tipo${NC}  ${BOLD}Tamanho${NC}  ${BOLD}Usado${NC}   ${BOLD}Livre${NC}   ${BOLD}Uso%${NC} ${BOLD}Barra Visual${NC}                    ${BOLD}Montagem${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Mostrar discos
    for ((i=0; i<${#FILESYSTEMS[@]}; i++)); do
        local filesystem="${FILESYSTEMS[i]}"
        local fstype="${TYPES[i]}"
        local size="${SIZES[i]}"
        local used="${USED[i]}"
        local avail="${AVAILABLE[i]}"
        local percent="${PERCENTAGES[i]}"
        local mountpoint="${MOUNTPOINTS[i]}"
        
        # Status indicator
        local status_color=$GREEN
        if [ $percent -ge 90 ]; then
            status_color=$RED
        elif [ $percent -ge 75 ]; then
            status_color=$YELLOW
        elif [ $percent -ge 50 ]; then
            status_color=$BLUE
        fi
        
        # Formatação
        local fs_display=$(truncate_text "$filesystem" 35)
        local type_display=$(printf "%-5s" "${fstype:0:5}")
        local size_f=$(printf "%7s" "$size")
        local used_f=$(printf "%7s" "$used")
        local avail_f=$(printf "%7s" "$avail")
        local percent_f=$(printf "%3s" "$percent")
        local mount_display=$(truncate_text "$mountpoint" 15)
        
        # Barra visual
        local bar=$(create_bar $percent)
        
        # Destacar item selecionado
        local line_color=""
        local marker="  "
        if [ $i -eq $SELECTED ]; then
            line_color=$WHITE
            marker="${CYAN}${ARROW} ${NC}"
        fi
        
        echo -e "${WHITE}║${line_color}${marker}${status_color}${BULLET}${NC} ${fs_display} ${type_display} ${size_f} ${used_f} ${avail_f} ${status_color}${percent_f}%${NC} ${bar} ${CYAN}${mount_display}${NC}"
    done
    
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}Item selecionado:${NC} ${GREEN}${FILESYSTEMS[SELECTED]}${NC} (${YELLOW}${PERCENTAGES[SELECTED]}%${NC} usado)"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Navegação:${NC} [↑↓] ou [j/k] Mover | [Enter] Detalhes | [r] Refresh | [a] Auto | [c] Cache | [q] Sair"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Função para mostrar detalhes
show_disk_details() {
    local index=$1
    clear
    
    local filesystem="${FILESYSTEMS[index]}"
    local fstype="${TYPES[index]}"
    local size="${SIZES[index]}"
    local used="${USED[index]}"
    local avail="${AVAILABLE[index]}"
    local percent="${PERCENTAGES[index]}"
    local mountpoint="${MOUNTPOINTS[index]}"
    
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                                    DETALHES DO DISCO                                               ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    
    local status_color=$GREEN
    local status_text="SAUDÁVEL"
    if [ $percent -ge 95 ]; then
        status_color=$RED
        status_text="CRÍTICO"
    elif [ $percent -ge 85 ]; then
        status_color=$YELLOW
        status_text="ATENÇÃO"
    elif [ $percent -ge 70 ]; then
        status_color=$BLUE
        status_text="MODERADO"
    fi
    
    echo -e "${WHITE}║${NC} ${BOLD}Status:${NC} ${status_color}${BULLET} ${status_text}${NC}"
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}📁 Sistema de Arquivos:${NC} ${CYAN}$filesystem${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}📂 Ponto de Montagem:${NC}   ${CYAN}$mountpoint${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}🗂️  Tipo:${NC}               ${YELLOW}$fstype${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}💾 Tamanho Total:${NC}       ${YELLOW}$size${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}📊 Espaço Usado:${NC}        ${RED}$used${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}💿 Espaço Livre:${NC}        ${GREEN}$avail${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}📈 Uso:${NC}                 ${status_color}$percent%${NC}"
    echo -e "${WHITE}║${NC}"
    
    # Barra visual grande
    local big_bar=$(create_bar $percent)
    echo -e "${WHITE}║${NC} ${BOLD}Visualização:${NC} $big_bar ${status_color}$percent%${NC}"
    echo -e "${WHITE}║${NC}"
    
    # Informações adicionais
    local inode_info=$(df -i "$mountpoint" 2>/dev/null | tail -n 1)
    if [ -n "$inode_info" ]; then
        local inode_used=$(echo "$inode_info" | awk '{print $3}')
        local inode_avail=$(echo "$inode_info" | awk '{print $4}')
        local inode_percent=$(echo "$inode_info" | awk '{print $5}' | tr -d '%')
        echo -e "${WHITE}║${NC} ${BOLD}🔗 Inodes:${NC} Usados: ${YELLOW}$inode_used${NC} | Livres: ${GREEN}$inode_avail${NC} | Uso: ${CYAN}$inode_percent%${NC}"
    fi
    
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Comandos:${NC} [b] Voltar | [d] Analisar diretório | [c] Limpar cache | [q] Sair"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Loop de comandos nos detalhes
    while true; do
        echo -ne "\n${CYAN}Comando (detalhes): ${NC}"
        local cmd=$(read_key)
        
        case $cmd in
            'b'|'B')
                return
                ;;
            'd'|'D')
                analyze_directory "$mountpoint"
                ;;
            'c'|'C')
                clear_cache
                ;;
            'q'|'Q')
                restore_terminal
                exit 0
                ;;
            'ENTER')
                return
                ;;
        esac
    done
}

# Função para análise de diretório
analyze_directory() {
    local path="$1"
    echo -e "\n${YELLOW}🔍 Analisando: $path${NC}"
    echo -e "${CYAN}Top 10 maiores diretórios:${NC}\n"
    
    du -h "$path"/* 2>/dev/null | sort -hr | head -10 | while read size dir; do
        echo -e "${GREEN}$size${NC} - ${BLUE}$(basename "$dir")${NC}"
    done
    
    echo -e "\n${CYAN}Pressione qualquer tecla para continuar...${NC}"
    read_key > /dev/null
}

# Função para limpar cache
clear_cache() {
    echo -e "\n${YELLOW}🧹 Limpando caches...${NC}"
    sync
    echo 1 > /proc/sys/vm/drop_caches 2>/dev/null && echo -e "${GREEN}✅ Cache limpo${NC}" || echo -e "${RED}❌ Erro (root necessário)${NC}"
    echo -e "\n${CYAN}Pressione qualquer tecla para continuar...${NC}"
    read_key > /dev/null
}

# Função de navegação principal CORRIGIDA
navigate() {
    setup_terminal
    
    while true; do
        get_disk_data
        draw_interface
        
        if [ ${#FILESYSTEMS[@]} -eq 0 ]; then
            echo -e "\n${CYAN}Pressione qualquer tecla para sair...${NC}"
            read_key > /dev/null
            restore_terminal
            exit 0
        fi
        
        # Aguardar comando
        if [ "$AUTO_REFRESH" = true ]; then
            # Auto-refresh com timeout
            local cmd=""
            for ((i=0; i<REFRESH_INTERVAL; i++)); do
                echo -ne "\r${GRAY}Auto-refresh em $((REFRESH_INTERVAL - i))s... (pressione qualquer tecla)${NC}"
                if timeout 1 bash -c 'read -n 1' 2>/dev/null; then
                    cmd=$(read_key)
                    break
                fi
            done
            echo -ne "\r${NC}"
        else
            echo -ne "\n${CYAN}Comando: ${NC}"
            local cmd=$(read_key)
        fi
        
        # Processar comando
        case $cmd in
            'j'|'J'|'DOWN')
                if [ $SELECTED -lt $((${#FILESYSTEMS[@]} - 1)) ]; then
                    SELECTED=$((SELECTED + 1))
                fi
                ;;
            'k'|'K'|'UP')
                if [ $SELECTED -gt 0 ]; then
                    SELECTED=$((SELECTED - 1))
                fi
                ;;
            'ENTER'|'SPACE')
                show_disk_details $SELECTED
                ;;
            'r'|'R')
                echo -e "\n${GREEN}🔄 Atualizando...${NC}"
                sleep 1
                ;;
            'a'|'A')
                if [ "$AUTO_REFRESH" = true ]; then
                    AUTO_REFRESH=false
                    echo -e "\n${YELLOW}Auto-refresh DESATIVADO${NC}"
                else
                    AUTO_REFRESH=true
                    echo -e "\n${GREEN}Auto-refresh ATIVADO (${REFRESH_INTERVAL}s)${NC}"
                fi
                sleep 1
                ;;
            'c'|'C')
                clear_cache
                ;;
            'q'|'Q'|'CTRL_C')
                echo -e "\n${GREEN}👋 Saindo...${NC}"
                restore_terminal
                exit 0
                ;;
            'h'|'H'|'?')
                show_help
                ;;
        esac
    done
}

# Função de ajuda
show_help() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                                     AJUDA                                                          ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}Navegação Principal:${NC}"
    echo -e "${WHITE}║${NC}   ${CYAN}↑/k${NC}     - Mover para cima"
    echo -e "${WHITE}║${NC}   ${CYAN}↓/j${NC}     - Mover para baixo"
    echo -e "${WHITE}║${NC}   ${CYAN}Enter${NC}   - Ver detalhes do disco"
    echo -e "${WHITE}║${NC}   ${CYAN}r${NC}       - Atualizar dados"
    echo -e "${WHITE}║${NC}   ${CYAN}a${NC}       - Auto-refresh on/off"
    echo -e "${WHITE}║${NC}   ${CYAN}c${NC}       - Limpar cache"
    echo -e "${WHITE}║${NC}   ${CYAN}q${NC}       - Sair"
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${BOLD}Nos Detalhes:${NC}"
    echo -e "${WHITE}║${NC}   ${CYAN}b${NC}       - Voltar"
    echo -e "${WHITE}║${NC}   ${CYAN}d${NC}       - Analisar diretório"
    echo -e "${WHITE}║${NC}   ${CYAN}c${NC}       - Limpar cache"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}Pressione qualquer tecla para continuar...${NC}"
    read_key > /dev/null
}

# Função principal
main() {
    # Capturar Ctrl+C
    trap 'restore_terminal; echo -e "\n${GREEN}Saindo...${NC}"; exit 0' INT TERM
    
    clear
    echo -e "${CYAN}  ██████╗ ██╗███████╗██╗  ██╗██╗   ██╗██╗███████╗██╗    ██╗${NC}"
    echo -e "${CYAN}  ██╔══██╗██║██╔════╝██║ ██╔╝██║   ██║██║██╔════╝██║    ██║${NC}"
    echo -e "${CYAN}  ██║  ██║██║███████╗█████╔╝ ██║   ██║██║█████╗  ██║ █╗ ██║${NC}"
    echo -e "${CYAN}  ██║  ██║██║╚════██║██╔═██╗ ╚██╗ ██╔╝██║██╔══╝  ██║███╗██║${NC}"
    echo -e "${CYAN}  ██████╔╝██║███████║██║  ██╗ ╚████╔╝ ██║███████╗╚███╔███╔╝${NC}"
    echo -e "${CYAN}  ╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝ ╚══╝╚══╝${NC}"
    echo -e "\n${YELLOW}                    ULTRA - Versão 2.1 (Navegação Corrigida)${NC}"
    echo -e "${GREEN}                      Carregando interface...${NC}"
    sleep 2
    
    navigate
}

# Executar
main "$@"
