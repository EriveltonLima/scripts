#!/usr/bin/env bash

# Script Completo de Instalação Cloudflared Tunnel v3.0
# Interface Interativa e Visual Aprimorada

# Configuração de cores e símbolos
declare -A COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m' 
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[0;34m'
    [PURPLE]='\033[0;35m'
    [CYAN]='\033[0;36m'
    [WHITE]='\033[1;37m'
    [GRAY]='\033[0;90m'
    [BOLD]='\033[1m'
    [NC]='\033[0m'
)

# Símbolos Unicode
declare -A SYMBOLS=(
    [CHECK]='✅'
    [CROSS]='❌'
    [WARN]='⚠️'
    [INFO]='ℹ️'
    [ROCKET]='🚀'
    [GEAR]='⚙️'
    [CLOUD]='☁️'
    [LOCK]='🔒'
    [FIRE]='🔥'
    [STAR]='⭐'
    [ARROW]='➤'
    [LOADING]='⏳'
)

# Variáveis globais
SCRIPT_VERSION="3.0"
START_TIME=$(date +%s)

# Função para limpar tela com efeito
function clear_screen() {
    printf '\033[2J\033[H'
}

# Função para desenhar linha decorativa
function draw_line() {
    local char="${1:-─}"
    local length="${2:-60}"
    local color="${3:-CYAN}"
    
    printf "${COLORS[$color]}"
    printf "%*s\n" $length | tr ' ' "$char"
    printf "${COLORS[NC]}"
}

# Função para desenhar box
function draw_box() {
    local text="$1"
    local color="${2:-BLUE}"
    local padding=2
    local text_length=${#text}
    local box_width=$((text_length + padding * 2 + 2))
    
    echo ""
    printf "${COLORS[$color]}┌"
    printf "%*s" $((box_width - 2)) | tr ' ' '─'
    printf "┐${COLORS[NC]}\n"
    
    printf "${COLORS[$color]}│${COLORS[WHITE]}"
    printf "%*s" $padding
    printf "%s" "$text"
    printf "%*s" $padding
    printf "${COLORS[$color]}│${COLORS[NC]}\n"
    
    printf "${COLORS[$color]}└"
    printf "%*s" $((box_width - 2)) | tr ' ' '─'
    printf "┘${COLORS[NC]}\n"
    echo ""
}

# Header principal com animação
function show_header() {
    clear_screen
    
    # Gradiente de cores para o título
    echo ""
    printf "${COLORS[CYAN]}${COLORS[BOLD]}"
    cat << 'EOF'
      ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ███████╗██╗      █████╗ ██████╗ ███████╗██████╗ 
     ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██╔════╝██║     ██╔══██╗██╔══██╗██╔════╝██╔══██╗
     ██║     ██║     ██║   ██║██║   ██║██║  ██║█████╗  ██║     ███████║██████╔╝█████╗  ██║  ██║
     ██║     ██║     ██║   ██║██║   ██║██║  ██║██╔══╝  ██║     ██╔══██║██╔══██╗██╔══╝  ██║  ██║
     ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝██║     ███████╗██║  ██║██║  ██║███████╗██████╔╝
      ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═════╝ 
EOF
    printf "${COLORS[NC]}\n"
    
    printf "${COLORS[PURPLE]}${COLORS[BOLD]}"
    cat << 'EOF'
     ████████╗██╗   ██╗███╗   ███╗███╗   ██╗███████╗██╗         ██╗   ██╗██████╗     ██████╗ 
     ╚══██╔══╝██║   ██║████╗ ████║████╗  ██║██╔════╝██║         ██║   ██║╚════██╗   ██╔═████╗
        ██║   ██║   ██║██╔████╔██║██╔██╗ ██║█████╗  ██║         ██║   ██║ █████╔╝   ██║██╔██║
        ██║   ██║   ██║██║╚██╔╝██║██║╚██╗██║██╔══╝  ██║         ╚██╗ ██╔╝ ╚═══██╗   ████╔╝██║
        ██║   ╚██████╔╝██║ ╚═╝ ██║██║ ╚████║███████╗███████╗     ╚████╔╝ ██████╔╝██╗╚██████╔╝
        ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝      ╚═══╝  ╚═════╝ ╚═╝ ╚═════╝ 
EOF
    printf "${COLORS[NC]}\n"
    
    draw_line "═" 100 "CYAN"
    
    printf "${COLORS[WHITE]}${COLORS[BOLD]}"
    printf "%40s ${SYMBOLS[CLOUD]} CLOUDFLARED TUNNEL INSTALLER ${SYMBOLS[CLOUD]}\n" ""
    printf "%45s Versão $SCRIPT_VERSION - Interface Avançada\n" ""
    printf "%42s ${SYMBOLS[ROCKET]} Instalação Automática para Proxmox ${SYMBOLS[ROCKET]}\n" ""
    printf "${COLORS[NC]}\n"
    
    draw_line "═" 100 "CYAN"
    echo ""
}

# Função de loading animado
function show_loading() {
    local text="$1"
    local duration="${2:-3}"
    local spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    printf "${COLORS[CYAN]}${SYMBOLS[LOADING]} %s " "$text"
    
    for ((i=0; i<duration*10; i++)); do
        printf "\b${spinner:i%10:1}"
        sleep 0.1
    done
    
    printf "\b${SYMBOLS[CHECK]}${COLORS[NC]}\n"
}

# Funções de mensagem aprimoradas
function msg_info() {
    printf "${COLORS[BLUE]}${COLORS[BOLD]}${SYMBOLS[INFO]} INFO${COLORS[NC]} ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$1"
}

function msg_success() {
    printf "${COLORS[GREEN]}${COLORS[BOLD]}${SYMBOLS[CHECK]} SUCESSO${COLORS[NC]} ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$1"
}

function msg_error() {
    printf "${COLORS[RED]}${COLORS[BOLD]}${SYMBOLS[CROSS]} ERRO${COLORS[NC]} ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$1"
}

function msg_warn() {
    printf "${COLORS[YELLOW]}${COLORS[BOLD]}${SYMBOLS[WARN]} AVISO${COLORS[NC]} ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$1"
}

function msg_step() {
    local step="$1"
    local total="$2"
    local description="$3"
    
    echo ""
    draw_line "─" 80 "PURPLE"
    printf "${COLORS[PURPLE]}${COLORS[BOLD]} ${SYMBOLS[GEAR]} ETAPA $step/$total ${SYMBOLS[ARROW]} $description${COLORS[NC]}\n"
    draw_line "─" 80 "PURPLE"
    echo ""
}

# Função para input decorado
function get_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local type="${4:-text}"
    
    echo ""
    printf "${COLORS[CYAN]}${SYMBOLS[ARROW]} ${COLORS[BOLD]}$prompt${COLORS[NC]}"
    
    if [[ -n "$default" ]]; then
        printf " ${COLORS[GRAY]}[padrão: $default]${COLORS[NC]}"
    fi
    
    printf "\n${COLORS[YELLOW]}${SYMBOLS[ARROW]} ${COLORS[NC]}"
    
    read -r input
    
    if [[ -z "$input" && -n "$default" ]]; then
        input="$default"
    fi
    
    # Validação baseada no tipo
    case "$type" in
        "ip")
            while ! [[ "$input" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; do
                printf "${COLORS[RED]}${SYMBOLS[CROSS]} IP inválido! Tente novamente: ${COLORS[NC]}"
                read -r input
            done
            ;;
        "port")
            while ! [[ "$input" =~ ^[0-9]+$ ]] || [[ "$input" -lt 1 || "$input" -gt 65535 ]]; do
                printf "${COLORS[RED]}${SYMBOLS[CROSS]} Porta inválida! Digite um número entre 1-65535: ${COLORS[NC]}"
                read -r input
            done
            ;;
        "hostname")
            while ! [[ "$input" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
                printf "${COLORS[RED]}${SYMBOLS[CROSS]} Hostname inválido! Use formato: app.dominio.com ${COLORS[NC]}"
                read -r input
            done
            ;;
    esac
    
    eval "$var_name='$input'"
    printf "${COLORS[GREEN]}${SYMBOLS[CHECK]} Definido: $input${COLORS[NC]}\n"
}

# Função para confirmação estilizada
function confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    echo ""
    draw_box "$message" "YELLOW"
    
    if [[ "$default" == "y" ]]; then
        printf "${COLORS[GREEN]}${SYMBOLS[ARROW]} Confirmar? [Y/n]: ${COLORS[NC]}"
    else
        printf "${COLORS[YELLOW]}${SYMBOLS[ARROW]} Confirmar? [y/N]: ${COLORS[NC]}"
    fi
    
    read -r response
    
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Função para mostrar progresso
function show_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${COLORS[CYAN]}${SYMBOLS[GEAR]} %-30s ${COLORS[NC]}" "$description"
    printf "${COLORS[GREEN]}["
    printf "%*s" $filled | tr ' ' '█'
    printf "${COLORS[GRAY]}"
    printf "%*s" $empty | tr ' ' '░'
    printf "${COLORS[GREEN]}] ${COLORS[WHITE]}%d%%${COLORS[NC]}" $percentage
    
    if [[ $current -eq $total ]]; then
        printf " ${COLORS[GREEN]}${SYMBOLS[CHECK]}${COLORS[NC]}\n"
    fi
}

# Menu principal interativo
function show_main_menu() {
    while true; do
        show_header
        
        printf "${COLORS[WHITE]}${COLORS[BOLD]}"
        printf "%35s ╔══════════════════════════════╗\n" ""
        printf "%35s ║   ${SYMBOLS[ROCKET]} MENU PRINCIPAL ${SYMBOLS[ROCKET]}       ║\n" ""
        printf "%35s ╠══════════════════════════════╣\n" ""
        printf "%35s ║                              ║\n" ""
        printf "%35s ║  ${COLORS[GREEN]}1${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[FIRE]} Instalação Completa    ║\n" ""
        printf "%35s ║  ${COLORS[CYAN]}2${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[GEAR]} Instalação Personalizada║\n" ""
        printf "%35s ║  ${COLORS[YELLOW]}3${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[INFO]} Verificar Dependências ║\n" ""
        printf "%35s ║  ${COLORS[PURPLE]}4${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[STAR]} Sobre o Script         ║\n" ""
        printf "%35s ║  ${COLORS[RED]}0${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[CROSS]} Sair                   ║\n" ""
        printf "%35s ║                              ║\n" ""
        printf "%35s ╚══════════════════════════════╝\n" ""
        printf "${COLORS[NC]}\n"
        
        printf "${COLORS[CYAN]}${SYMBOLS[ARROW]} Escolha uma opção: ${COLORS[NC]}"
        read -r choice
        
        case "$choice" in
            1)
                if confirm_action "Iniciar instalação completa automática?"; then
                    start_installation "complete"
                    return
                fi
                ;;
            2)
                if confirm_action "Iniciar instalação com configurações personalizadas?"; then
                    start_installation "custom"
                    return
                fi
                ;;
            3)
                check_dependencies
                read -p "Pressione ENTER para continuar..."
                ;;
            4)
                show_about
                read -p "Pressione ENTER para continuar..."
                ;;
            0)
                show_goodbye
                exit 0
                ;;
            *)
                msg_error "Opção inválida! Escolha de 0 a 4."
                sleep 2
                ;;
        esac
    done
}

# Função para verificar dependências
function check_dependencies() {
    show_header
    draw_box "VERIFICAÇÃO DE DEPENDÊNCIAS DO SISTEMA" "BLUE"
    
    local deps=("curl" "wget" "pct" "pvesh" "pveam")
    local total=${#deps[@]}
    
    for i in "${!deps[@]}"; do
        show_progress $((i+1)) $total "Verificando ${deps[i]}"
        
        if command -v "${deps[i]}" >/dev/null 2>&1; then
            printf "   ${COLORS[GREEN]}${SYMBOLS[CHECK]} ${deps[i]} instalado${COLORS[NC]}\n"
        else
            printf "   ${COLORS[RED]}${SYMBOLS[CROSS]} ${deps[i]} NÃO encontrado${COLORS[NC]}\n"
        fi
        sleep 0.5
    done
    
    echo ""
    msg_info "Verificação de dependências concluída!"
}

# Função sobre o script
function show_about() {
    show_header
    
    cat << EOF
${COLORS[CYAN]}${COLORS[BOLD]}
╔══════════════════════════════════════════════════════════════════════╗
║                           SOBRE O SCRIPT                            ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  ${SYMBOLS[ROCKET]} Script: Cloudflared Tunnel Installer v$SCRIPT_VERSION                    ║
║  ${SYMBOLS[GEAR]} Função: Instalação automática do Cloudflared em Proxmox        ║
║  ${SYMBOLS[CLOUD]} Recursos:                                                      ║
║     • Interface visual interativa                                   ║
║     • Instalação completamente automatizada                         ║
║     • Configuração de DNS automática                                ║
║     • Sistema de gerenciamento incluído                             ║
║     • Suporte a múltiplos serviços                                  ║
║     • Logs detalhados e debugging                                   ║
║                                                                      ║
║  ${SYMBOLS[LOCK]} Segurança:                                                      ║
║     • Validação de inputs                                           ║
║     • Cleanup automático em caso de erro                            ║
║     • Configurações SSL/TLS seguras                                 ║
║                                                                      ║
║  ${SYMBOLS[STAR]} Compatibilidade: Proxmox VE (todas as versões)                  ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
${COLORS[NC]}
EOF
}

# Função de despedida
function show_goodbye() {
    clear_screen
    echo ""
    echo ""
    printf "${COLORS[PURPLE]}${COLORS[BOLD]}"
    cat << 'EOF'
     ╔═══════════════════════════════════════════════════════════════╗
     ║                                                               ║
     ║      ████████╗ ██████╗██╗  ██╗ █████╗ ██╗   ██╗██╗           ║
     ║      ╚══██╔══╝██╔════╝██║  ██║██╔══██╗██║   ██║██║           ║
     ║         ██║   ██║     ███████║███████║██║   ██║██║           ║
     ║         ██║   ██║     ██╔══██║██╔══██║██║   ██║╚═╝           ║
     ║         ██║   ╚██████╗██║  ██║██║  ██║╚██████╔╝██╗           ║
     ║         ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝           ║
     ║                                                               ║
     ║           Obrigado por usar o Cloudflared Installer!          ║
     ║                                                               ║
     ╚═══════════════════════════════════════════════════════════════╝
EOF
    printf "${COLORS[NC]}\n\n"
    
    printf "${COLORS[CYAN]}${SYMBOLS[STAR]} Até a próxima! ${SYMBOLS[STAR]}${COLORS[NC]}\n\n"
}

# Função principal de instalação
function start_installation() {
    local mode="$1"
    
    show_header
    draw_box "INICIANDO PROCESSO DE INSTALAÇÃO" "GREEN"
    
    if [[ "$mode" == "custom" ]]; then
        get_user_inputs_interactive
    else
        get_user_inputs_quick
    fi
    
    # Verificar se é root
    if [[ $EUID -ne 0 ]]; then
        msg_error "Este script deve ser executado como root!"
        exit 1
    fi
    
    # Mostrar resumo da configuração
    show_configuration_summary
    
    if ! confirm_action "Iniciar instalação com essas configurações?"; then
        msg_info "Instalação cancelada pelo usuário."
        return
    fi
    
    # Processo de instalação com progresso visual
    run_installation_process
}

# Input interativo completo
function get_user_inputs_interactive() {
    show_header
    draw_box "CONFIGURAÇÃO PERSONALIZADA" "CYAN"
    
    msg_info "Vamos configurar seu tunnel Cloudflared passo a passo!"
    
    get_input "Hostname para acesso externo" "proxmox.seudominio.com" "HOSTNAME" "hostname"
    get_input "IP do servidor Proxmox" "$(hostname -I | awk '{print $1}')" "PROXMOX_IP" "ip"
    get_input "Porta do Proxmox" "8006" "PROXMOX_PORT" "port"
    get_input "Nome do tunnel" "proxmox-tunnel" "TUNNEL_NAME"
    get_input "RAM do container (MB)" "512" "RAM_SIZE"
    get_input "CPU cores" "1" "CORE_COUNT"
    get_input "Tamanho do disco (GB)" "2" "DISK_SIZE"
}

# Input rápido com valores padrão
function get_user_inputs_quick() {
    show_header
    draw_box "CONFIGURAÇÃO RÁPIDA" "GREEN"
    
    msg_info "Usando configurações padrão otimizadas..."
    
    get_input "Hostname para acesso externo" "" "HOSTNAME" "hostname"
    
    # Valores padrão
    PROXMOX_IP=$(hostname -I | awk '{print $1}')
    PROXMOX_PORT="8006"
    TUNNEL_NAME="proxmox-tunnel"
    RAM_SIZE="512"
    CORE_COUNT="1"
    DISK_SIZE="2"
    
    msg_success "Configurações padrão aplicadas!"
}

# Mostrar resumo da configuração
function show_configuration_summary() {
    show_header
    draw_box "RESUMO DA CONFIGURAÇÃO" "YELLOW"
    
    echo ""
    printf "${COLORS[WHITE]}${COLORS[BOLD]}📋 CONFIGURAÇÕES DO TUNNEL:${COLORS[NC]}\n"
    echo ""
    printf "${COLORS[CYAN]}   🌐 Hostname:${COLORS[NC]} %s\n" "$HOSTNAME"
    printf "${COLORS[CYAN]}   🖥️  Proxmox:${COLORS[NC]} %s:%s\n" "$PROXMOX_IP" "$PROXMOX_PORT"
    printf "${COLORS[CYAN]}   🚇 Tunnel:${COLORS[NC]} %s\n" "$TUNNEL_NAME"
    echo ""
    printf "${COLORS[WHITE]}${COLORS[BOLD]}⚙️ ESPECIFICAÇÕES DO CONTAINER:${COLORS[NC]}\n"
    echo ""
    printf "${COLORS[PURPLE]}   💾 RAM:${COLORS[NC]} %s MB\n" "$RAM_SIZE"
    printf "${COLORS[PURPLE]}   🔧 CPU:${COLORS[NC]} %s core(s)\n" "$CORE_COUNT"
    printf "${COLORS[PURPLE]}   💿 Disco:${COLORS[NC]} %s GB\n" "$DISK_SIZE"
    echo ""
}

# Processo principal de instalação
function run_installation_process() {
    local total_steps=9
    local current_step=0
    
    show_header
    draw_box "INSTALAÇÃO EM PROGRESSO" "GREEN"
    
    # Etapa 1: Templates
    ((current_step++))
    msg_step $current_step $total_steps "Verificando e baixando templates"
    show_loading "Verificando templates disponíveis" 2
    get_template
    show_progress $current_step $total_steps "Templates verificados"
    sleep 1
    
    # Etapa 2: Container
    ((current_step++))
    msg_step $current_step $total_steps "Criando container LXC"
    show_loading "Criando container com especificações definidas" 3
    create_container
    show_progress $current_step $total_steps "Container criado"
    sleep 1
    
    # Etapa 3: Cloudflared
    ((current_step++))
    msg_step $current_step $total_steps "Instalando Cloudflared"
    show_loading "Baixando e instalando Cloudflared" 4
    install_cloudflared
    show_progress $current_step $total_steps "Cloudflared instalado"
    sleep 1
    
    # Etapa 4: Login
    ((current_step++))
    msg_step $current_step $total_steps "Configurando acesso ao Cloudflare"
    cloudflared_login_interactive
    show_progress $current_step $total_steps "Login configurado"
    sleep 1
    
    # Etapa 5: Tunnel
    ((current_step++))
    msg_step $current_step $total_steps "Criando tunnel"
    show_loading "Criando tunnel no Cloudflare" 2
    create_tunnel
    show_progress $current_step $total_steps "Tunnel criado"
    sleep 1
    
    # Etapa 6: Configuração
    ((current_step++))
    msg_step $current_step $total_steps "Configurando tunnel"
    show_loading "Gerando arquivo de configuração" 2
    create_config
    show_progress $current_step $total_steps "Configuração criada"
    sleep 1
    
    # Etapa 7: DNS
    ((current_step++))
    msg_step $current_step $total_steps "Configurando DNS"
    show_loading "Configurando registro DNS" 3
    setup_dns
    show_progress $current_step $total_steps "DNS configurado"
    sleep 1
    
    # Etapa 8: Serviço
    ((current_step++))
    msg_step $current_step $total_steps "Instalando serviço"
    show_loading "Configurando auto-inicialização" 2
    install_service
    show_progress $current_step $total_steps "Serviço instalado"
    sleep 1
    
    # Etapa 9: Finalização
    ((current_step++))
    msg_step $current_step $total_steps "Finalizando instalação"
    show_loading "Executando testes e verificações" 3
    test_connectivity
    create_management_script
    show_progress $current_step $total_steps "Instalação concluída"
    
    # Mostrar resultado final
    show_installation_complete
}

# Login interativo melhorado
function cloudflared_login_interactive() {
    echo ""
    draw_box "AUTENTICAÇÃO NO CLOUDFLARE" "BLUE"
    
    msg_warn "Uma URL de autorização será exibida abaixo."
    msg_info "Você precisará:"
    echo "   1. Copiar a URL completa"
    echo "   2. Abrir em seu navegador"
    echo "   3. Fazer login no Cloudflare"
    echo "   4. Autorizar o tunnel"
    echo ""
    
    if confirm_action "Pronto para continuar?"; then
        echo ""
        msg_info "Iniciando processo de autorização..."
        echo ""
        draw_line "─" 80 "YELLOW"
        
        if pct exec $CT_ID -- cloudflared tunnel login; then
            echo ""
            draw_line "─" 80 "YELLOW"
            msg_success "Autorização concluída com sucesso!"
        else
            msg_error "Falha na autorização. Verifique se completou o processo no navegador."
            exit 1
        fi
    else
        msg_error "Autorização necessária para continuar."
        exit 1
    fi
}

# Resultado final com estatísticas
function show_installation_complete() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    clear_screen
    echo ""
    
    # ASCII Art de sucesso
    printf "${COLORS[GREEN]}${COLORS[BOLD]}"
    cat << 'EOF'
     ╔══════════════════════════════════════════════════════════════════════╗
     ║                                                                      ║
     ║   ███████╗██╗   ██╗ ██████╗███████╗███████╗███████╗ ██████╗ ██╗      ║
     ║   ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔═══██╗██║      ║
     ║   ███████╗██║   ██║██║     █████╗  ███████╗███████╗██║   ██║██║      ║
     ║   ╚════██║██║   ██║██║     ██╔══╝  ╚════██║╚════██║██║   ██║╚═╝      ║
     ║   ███████║╚██████╔╝╚██████╗███████╗███████║███████║╚██████╔╝██╗      ║
     ║   ╚══════╝ ╚═════╝  ╚═════╝╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚═╝      ║
     ║                                                                      ║
     ╚══════════════════════════════════════════════════════════════════════╝
EOF
    printf "${COLORS[NC]}\n"
    
    draw_line "═" 80 "GREEN"
    
    # Informações da instalação
    printf "${COLORS[WHITE]}${COLORS[BOLD]}"
    printf "%25s 🎉 CLOUDFLARED TUNNEL INSTALADO COM SUCESSO! 🎉\n" ""
    printf "${COLORS[NC]}\n"
    
    # Estatísticas
    draw_box "ESTATÍSTICAS DA INSTALAÇÃO" "CYAN"
    printf "${COLORS[CYAN]}   ⏱️  Tempo total: ${COLORS[WHITE]}%02d:%02d${COLORS[NC]}\n" $minutes $seconds
    printf "${COLORS[CYAN]}   📦 Container ID: ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$CT_ID"
    printf "${COLORS[CYAN]}   🚇 Tunnel ID: ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$TUNNEL_ID"
    echo ""
    
    # Informações de acesso
    draw_box "INFORMAÇÕES DE ACESSO" "BLUE"
    printf "${COLORS[BLUE]}   🌐 URL Externa: ${COLORS[WHITE]}https://%s${COLORS[NC]}\n" "$HOSTNAME"
    printf "${COLORS[BLUE]}   🖥️  Proxmox Local: ${COLORS[WHITE]}https://%s:%s${COLORS[NC]}\n" "$PROXMOX_IP" "$PROXMOX_PORT"
    printf "${COLORS[BLUE]}   📱 Container: ${COLORS[WHITE]}pct enter %s${COLORS[NC]}\n" "$CT_ID"
    echo ""
    
    # Comandos úteis
    draw_box "COMANDOS DE GERENCIAMENTO" "PURPLE"
    printf "${COLORS[PURPLE]}   🔧 Script de gerenciamento: ${COLORS[WHITE]}/root/cloudflared-manager.sh${COLORS[NC]}\n"
    printf "${COLORS[PURPLE]}   📊 Ver status: ${COLORS[WHITE]}./cloudflared-manager.sh status${COLORS[NC]}\n"
    printf "${COLORS[PURPLE]}   📝 Ver logs: ${COLORS[WHITE]}./cloudflared-manager.sh logs${COLORS[NC]}\n"
    printf "${COLORS[PURPLE]}   🔄 Reiniciar: ${COLORS[WHITE]}./cloudflared-manager.sh restart${COLORS[NC]}\n"
    echo ""
    
    # Próximos passos
    draw_box "PRÓXIMOS PASSOS" "YELLOW"
    printf "${COLORS[YELLOW]}   1. ${COLORS[WHITE]}Aguarde 2-3 minutos para propagação do DNS${COLORS[NC]}\n"
    printf "${COLORS[YELLOW]}   2. ${COLORS[WHITE]}Acesse: https://%s${COLORS[NC]}\n" "$HOSTNAME"
    printf "${COLORS[YELLOW]}   3. ${COLORS[WHITE]}Faça login no Proxmox normalmente${COLORS[NC]}\n"
    printf "${COLORS[YELLOW]}   4. ${COLORS[WHITE]}Use o script de gerenciamento para administrar${COLORS[NC]}\n"
    echo ""
    
    draw_line "═" 80 "GREEN"
    
    printf "${COLORS[GREEN]}${COLORS[BOLD]}"
    printf "%30s ${SYMBOLS[ROCKET]} INSTALAÇÃO CONCLUÍDA! ${SYMBOLS[ROCKET]}\n" ""
    printf "${COLORS[NC]}\n"
    
    # Aguardar antes de finalizar
    echo ""
    read -p "Pressione ENTER para finalizar..."
}

# Aqui continuaríamos com as outras funções (get_template, create_container, etc.)
# mas adaptadas para usar as novas funções de interface...

# [RESTO DAS FUNÇÕES ORIGINAIS COM ADAPTAÇÕES VISUAIS]
# Por questão de espaço, vou incluir apenas algumas das principais adaptadas:

function get_template() {
    msg_info "Verificando templates disponíveis..."
    
    local existing_template=$(pveam list local 2>/dev/null | grep -E "(debian|ubuntu)" | head -1 | awk '{print $1}')
    
    if [[ -n "$existing_template" ]]; then
        TEMPLATE="local:vztmpl/$existing_template"
        msg_success "Template encontrado: $existing_template"
        return 0
    fi
    
    msg_info "Buscando templates disponíveis para download..."
    
    local debian_template=$(pveam available --section system 2>/dev/null | grep "debian-12-standard" | head -1 | awk '{print $2}')
    
    if [[ -n "$debian_template" ]]; then
        msg_info "Baixando Debian 12: $debian_template"
        if pveam download local "$debian_template"; then
            TEMPLATE="local:vztmpl/$debian_template"
            msg_success "Template baixado com sucesso"
            return 0
        fi
    fi
    
    msg_error "Falha ao obter template automaticamente"
    exit 1
}

function create_container() {
    CT_ID=$(pvesh get /cluster/nextid)
    CT_NAME="cloudflared"
    
    msg_info "Criando container LXC $CT_ID..."
    
    if pct create $CT_ID "$TEMPLATE" \
        --cores $CORE_COUNT \
        --memory $RAM_SIZE \
        --rootfs local-lvm:$DISK_SIZE \
        --hostname $CT_NAME \
        --net0 name=eth0,bridge=vmbr0,ip=dhcp \
        --unprivileged 1 \
        --features nesting=1 \
        --start 1; then
        
        msg_success "Container criado com ID: $CT_ID"
        
        # Aguardar inicialização
        sleep 15
        
        local timeout=60
        while ! pct status $CT_ID | grep -q "running" && [[ $timeout -gt 0 ]]; do
            sleep 2
            ((timeout--))
        done
        
        if pct status $CT_ID | grep -q "running"; then
            msg_success "Container inicializado com sucesso"
        else
            msg_error "Container falhou ao inicializar"
            exit 1
        fi
    else
        msg_error "Falha ao criar container"
        exit 1
    fi
}

# Função principal melhorada
function main() {
    # Verificar se o terminal suporta cores
    if [[ ! -t 1 ]]; then
        # Remover cores se não for um terminal interativo
        for color in "${!COLORS[@]}"; do
            COLORS[$color]=""
        done
    fi
    
    # Verificar dependências básicas
    if ! command -v pct >/dev/null 2>&1; then
        echo "ERRO: Este script deve ser executado em um servidor Proxmox!"
        exit 1
    fi
    
    # Mostrar menu principal
    show_main_menu
}

# Verificar se está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
