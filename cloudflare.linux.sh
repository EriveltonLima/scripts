#!/usr/bin/env bash

# Cloudflared Tunnel Installer para Linux v3.0
# Compatível com: Ubuntu Server, DietPi, Debian, CentOS, etc.
# Interface Visual Avançada

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
    [LINUX]='🐧'
    [SERVER]='🖥️'
    [NETWORK]='🌐'
    [SHIELD]='🛡️'
)

# Variáveis globais
SCRIPT_VERSION="3.0-Linux"
START_TIME=$(date +%s)
INSTALL_DIR="/opt/cloudflared"
CONFIG_DIR="/etc/cloudflared"
SERVICE_NAME="cloudflared"
DISTRO=""
PACKAGE_MANAGER=""

# Função para detectar distribuição
function detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO=$ID
        case $DISTRO in
            ubuntu|debian|raspbian)
                PACKAGE_MANAGER="apt"
                ;;
            centos|rhel|fedora)
                PACKAGE_MANAGER="yum"
                if command -v dnf >/dev/null 2>&1; then
                    PACKAGE_MANAGER="dnf"
                fi
                ;;
            arch)
                PACKAGE_MANAGER="pacman"
                ;;
            *)
                PACKAGE_MANAGER="apt"  # Fallback
                ;;
        esac
    else
        DISTRO="unknown"
        PACKAGE_MANAGER="apt"
    fi
}

# Funções de interface (reutilizando do script anterior)
function clear_screen() {
    printf '\033[2J\033[H'
}

function draw_line() {
    local char="${1:-─}"
    local length="${2:-60}"
    local color="${3:-CYAN}"
    
    printf "${COLORS[$color]}"
    printf "%*s\n" $length | tr ' ' "$char"
    printf "${COLORS[NC]}"
}

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

function show_header() {
    clear_screen
    
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
     ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗    ███████╗██████╗ ██╗████████╗██╗ ██████╗ ███╗   ██╗
     ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝    ██╔════╝██╔══██╗██║╚══██╔══╝██║██╔═══██╗████╗  ██║
     ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝     █████╗  ██║  ██║██║   ██║   ██║██║   ██║██╔██╗ ██║
     ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗     ██╔══╝  ██║  ██║██║   ██║   ██║██║   ██║██║╚██╗██║
     ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗    ███████╗██████╔╝██║   ██║   ██║╚██████╔╝██║ ╚████║
     ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝    ╚══════╝╚═════╝ ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
EOF
    printf "${COLORS[NC]}\n"
    
    draw_line "═" 100 "CYAN"
    
    printf "${COLORS[WHITE]}${COLORS[BOLD]}"
    printf "%35s ${SYMBOLS[LINUX]} CLOUDFLARED TUNNEL INSTALLER ${SYMBOLS[LINUX]}\n" ""
    printf "%40s Versão $SCRIPT_VERSION - Para Servidores Linux\n" ""
    printf "%35s ${SYMBOLS[ROCKET]} Ubuntu • DietPi • Debian • CentOS ${SYMBOLS[ROCKET]}\n" ""
    printf "${COLORS[NC]}\n"
    
    draw_line "═" 100 "CYAN"
    echo ""
}

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

# Menu principal
function show_main_menu() {
    while true; do
        show_header
        
        # Mostrar informações do sistema
        printf "${COLORS[GRAY]}${SYMBOLS[SERVER]} Sistema: ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$(lsb_release -d 2>/dev/null | cut -f2 || echo "$DISTRO")"
        printf "${COLORS[GRAY]}${SYMBOLS[GEAR]} Gerenciador: ${COLORS[WHITE]}%s${COLORS[NC]}\n\n" "$PACKAGE_MANAGER"
        
        printf "${COLORS[WHITE]}${COLORS[BOLD]}"
        printf "%35s ╔══════════════════════════════╗\n" ""
        printf "%35s ║   ${SYMBOLS[ROCKET]} MENU PRINCIPAL ${SYMBOLS[ROCKET]}       ║\n" ""
        printf "%35s ╠══════════════════════════════╣\n" ""
        printf "%35s ║                              ║\n" ""
        printf "%35s ║  ${COLORS[GREEN]}1${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[FIRE]} Instalação Completa    ║\n" ""
        printf "%35s ║  ${COLORS[CYAN]}2${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[GEAR]} Instalação Personalizada║\n" ""
        printf "%35s ║  ${COLORS[BLUE]}3${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[SHIELD]} Apenas Configurar Tunnel║\n" ""
        printf "%35s ║  ${COLORS[PURPLE]}4${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[INFO]} Verificar Sistema       ║\n" ""
        printf "%35s ║  ${COLORS[YELLOW]}5${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[STAR]} Gerenciar Serviço      ║\n" ""
        printf "%35s ║  ${COLORS[GRAY]}6${COLORS[WHITE]}${COLORS[BOLD]} ${SYMBOLS[INFO]} Sobre o Script         ║\n" ""
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
                fi
                ;;
            2)
                if confirm_action "Iniciar instalação personalizada?"; then
                    start_installation "custom"
                fi
                ;;
            3)
                configure_existing_installation
                ;;
            4)
                check_system_info
                read -p "Pressione ENTER para continuar..."
                ;;
            5)
                manage_service_menu
                ;;
            6)
                show_about
                read -p "Pressione ENTER para continuar..."
                ;;
            0)
                show_goodbye
                exit 0
                ;;
            *)
                msg_error "Opção inválida! Escolha de 0 a 6."
                sleep 2
                ;;
        esac
    done
}

# Verificação do sistema
function check_system_info() {
    show_header
    draw_box "INFORMAÇÕES DO SISTEMA" "BLUE"
    
    echo ""
    printf "${COLORS[CYAN]}${SYMBOLS[SERVER]} Sistema Operacional:${COLORS[NC]}\n"
    if command -v lsb_release >/dev/null 2>&1; then
        lsb_release -a 2>/dev/null | while read line; do
            printf "   ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$line"
        done
    else
        printf "   ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$(cat /etc/os-release | head -1)"
    fi
    
    echo ""
    printf "${COLORS[CYAN]}${SYMBOLS[GEAR]} Hardware:${COLORS[NC]}\n"
    printf "   ${COLORS[WHITE]}CPU: %s${COLORS[NC]}\n" "$(nproc) cores"
    printf "   ${COLORS[WHITE]}RAM: %s${COLORS[NC]}\n" "$(free -h | awk '/^Mem:/ {print $2}')"
    printf "   ${COLORS[WHITE]}Disco: %s${COLORS[NC]}\n" "$(df -h / | awk 'NR==2 {print $4 " livres de " $2}')"
    
    echo ""
    printf "${COLORS[CYAN]}${SYMBOLS[NETWORK]} Rede:${COLORS[NC]}\n"
    printf "   ${COLORS[WHITE]}IP Local: %s${COLORS[NC]}\n" "$(hostname -I | awk '{print $1}')"
    printf "   ${COLORS[WHITE]}Hostname: %s${COLORS[NC]}\n" "$(hostname)"
    
    echo ""
    printf "${COLORS[CYAN]}${SYMBOLS[SHIELD]} Status do Cloudflared:${COLORS[NC]}\n"
    if command -v cloudflared >/dev/null 2>&1; then
        printf "   ${COLORS[GREEN]}${SYMBOLS[CHECK]} Cloudflared instalado: %s${COLORS[NC]}\n" "$(cloudflared version | head -1)"
        
        if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
            printf "   ${COLORS[GREEN]}${SYMBOLS[CHECK]} Serviço: Ativo${COLORS[NC]}\n"
        else
            printf "   ${COLORS[YELLOW]}${SYMBOLS[WARN]} Serviço: Inativo${COLORS[NC]}\n"
        fi
        
        if [[ -f "$CONFIG_DIR/config.yml" ]]; then
            printf "   ${COLORS[GREEN]}${SYMBOLS[CHECK]} Configuração: Encontrada${COLORS[NC]}\n"
        else
            printf "   ${COLORS[YELLOW]}${SYMBOLS[WARN]} Configuração: Não encontrada${COLORS[NC]}\n"
        fi
    else
        printf "   ${COLORS[RED]}${SYMBOLS[CROSS]} Cloudflared: Não instalado${COLORS[NC]}\n"
    fi
    
    echo ""
}

# Verificar dependências e instalar se necessário
function install_dependencies() {
    msg_info "Verificando e instalando dependências..."
    
    # Atualizar lista de pacotes
    case $PACKAGE_MANAGER in
        apt)
            sudo apt update -qq
            sudo apt install -y curl wget systemd
            ;;
        yum|dnf)
            sudo $PACKAGE_MANAGER install -y curl wget systemd
            ;;
        pacman)
            sudo pacman -Sy --noconfirm curl wget systemd
            ;;
    esac
    
    msg_success "Dependências instaladas"
}

# Instalar Cloudflared
function install_cloudflared() {
    msg_info "Instalando Cloudflared..."
    
    # Criar diretórios
    sudo mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"
    
    # Detectar arquitetura
    local arch=$(uname -m)
    local download_url=""
    
    case $arch in
        x86_64)
            download_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
            ;;
        aarch64|arm64)
            download_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
            ;;
        armv7l)
            download_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
            ;;
        *)
            msg_error "Arquitetura não suportada: $arch"
            exit 1
            ;;
    esac
    
    # Baixar e instalar
    if curl -L "$download_url" -o /tmp/cloudflared; then
        sudo mv /tmp/cloudflared "$INSTALL_DIR/cloudflared"
        sudo chmod +x "$INSTALL_DIR/cloudflared"
        sudo ln -sf "$INSTALL_DIR/cloudflared" /usr/local/bin/cloudflared
        
        msg_success "Cloudflared instalado: $(cloudflared version | head -1)"
    else
        msg_error "Falha ao baixar Cloudflared"
        exit 1
    fi
}

# Login no Cloudflare
function cloudflared_login() {
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
        
        if sudo cloudflared tunnel login; then
            echo ""
            draw_line "─" 80 "YELLOW"
            msg_success "Autorização concluída com sucesso!"
            
            # Mover arquivos de credenciais para o diretório correto
            if [[ -d ~/.cloudflared ]]; then
                sudo cp -r ~/.cloudflared/* "$CONFIG_DIR/"
                sudo chown -R root:root "$CONFIG_DIR"
            fi
        else
            msg_error "Falha na autorização. Verifique se completou o processo no navegador."
            exit 1
        fi
    else
        msg_error "Autorização necessária para continuar."
        exit 1
    fi
}

# Criar tunnel
function create_tunnel() {
    msg_info "Criando tunnel: $TUNNEL_NAME"
    
    local tunnel_output=$(sudo cloudflared tunnel create "$TUNNEL_NAME" 2>&1)
    
    if [[ $? -eq 0 ]]; then
        msg_success "Tunnel criado com sucesso"
        TUNNEL_ID=$(echo "$tunnel_output" | grep -oP 'Created tunnel.*with id \K[a-f0-9-]+')
        msg_info "Tunnel ID: $TUNNEL_ID"
        
        # Mover arquivos de credenciais se necessário
        if [[ -f ~/.cloudflared/$TUNNEL_ID.json ]]; then
            sudo mv ~/.cloudflared/$TUNNEL_ID.json "$CONFIG_DIR/"
        fi
    else
        msg_error "Falha ao criar tunnel: $tunnel_output"
        exit 1
    fi
}

# Criar configuração
function create_config() {
    msg_info "Criando arquivo de configuração..."
    
    local config_content="tunnel: $TUNNEL_ID
credentials-file: $CONFIG_DIR/$TUNNEL_ID.json

ingress:"

    # Adicionar serviços configurados
    for service in "${SERVICES[@]}"; do
        IFS='|' read -r hostname service_url <<< "$service"
        config_content+="\n  - hostname: $hostname\n    service: $service_url"
        
        # Adicionar configurações SSL se necessário
        if [[ "$service_url" == https://* ]]; then
            config_content+="\n    originRequest:\n      noTLSVerify: true"
        fi
    done
    
    config_content+="\n  - service: http_status:404"

    echo -e "$config_content" | sudo tee "$CONFIG_DIR/config.yml" > /dev/null
    msg_success "Arquivo de configuração criado"
}

# Configurar DNS
function setup_dns() {
    msg_info "Configurando registros DNS..."
    
    for service in "${SERVICES[@]}"; do
        IFS='|' read -r hostname service_url <<< "$service"
        msg_info "Configurando DNS para: $hostname"
        
        if sudo cloudflared tunnel route dns "$TUNNEL_ID" "$hostname"; then
            msg_success "DNS configurado para $hostname"
        else
            msg_warn "Possível problema ao configurar DNS para $hostname"
        fi
    done
}

# Instalar serviço systemd
function install_service() {
    msg_info "Instalando serviço systemd..."
    
    local service_content="[Unit]
Description=Cloudflared Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --config $CONFIG_DIR/config.yml run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target"

    echo "$service_content" | sudo tee "/etc/systemd/system/$SERVICE_NAME.service" > /dev/null
    
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME
    
    msg_success "Serviço instalado e iniciado"
}

# Obter configurações do usuário
function get_user_inputs() {
    local mode="$1"
    
    show_header
    if [[ "$mode" == "custom" ]]; then
        draw_box "CONFIGURAÇÃO PERSONALIZADA" "CYAN"
    else
        draw_box "CONFIGURAÇÃO RÁPIDA" "GREEN"
    fi
    
    # Nome do tunnel
    get_input "Nome do tunnel" "linux-tunnel" "TUNNEL_NAME"
    
    # Configurar serviços
    SERVICES=()
    
    while true; do
        echo ""
        msg_info "Configurando serviços para expor..."
        
        get_input "Hostname para acesso externo" "" "hostname" "hostname"
        
        # Detectar serviços comuns
        echo ""
        printf "${COLORS[CYAN]}${SYMBOLS[GEAR]} Tipo de serviço:${COLORS[NC]}\n"
        echo "  1) Aplicação web (HTTP)"
        echo "  2) Aplicação web segura (HTTPS)"
        echo "  3) SSH"
        echo "  4) Personalizado"
        echo ""
        printf "${COLORS[YELLOW]}${SYMBOLS[ARROW]} Escolha o tipo [1-4]: ${COLORS[NC]}"
        read -r service_type
        
        case $service_type in
            1)
                get_input "Porta da aplicação" "80" "port" "port"
                service_url="http://localhost:$port"
                ;;
            2)
                get_input "Porta da aplicação" "443" "port" "port"
                service_url="https://localhost:$port"
                ;;
            3)
                service_url="ssh://localhost:22"
                ;;
            4)
                get_input "URL completa do serviço (ex: http://localhost:8080)" "" "service_url"
                ;;
            *)
                msg_error "Opção inválida"
                continue
                ;;
        esac
        
        SERVICES+=("$hostname|$service_url")
        msg_success "Serviço adicionado: $hostname -> $service_url"
        
        echo ""
        if ! confirm_action "Adicionar outro serviço?"; then
            break
        fi
    done
}

# Menu de gerenciamento de serviço
function manage_service_menu() {
    while true; do
        show_header
        draw_box "GERENCIAMENTO DO SERVIÇO" "PURPLE"
        
        # Status atual
        printf "${COLORS[CYAN]}${SYMBOLS[INFO]} Status atual:${COLORS[NC]} "
        if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
            printf "${COLORS[GREEN]}Ativo${COLORS[NC]}\n\n"
        else
            printf "${COLORS[RED]}Inativo${COLORS[NC]}\n\n"
        fi
        
        echo "1) Ver status detalhado"
        echo "2) Iniciar serviço"
        echo "3) Parar serviço"
        echo "4) Reiniciar serviço"
        echo "5) Ver logs em tempo real"
        echo "6) Ver configuração"
        echo "7) Testar conectividade"
        echo "0) Voltar ao menu principal"
        echo ""
        
        printf "${COLORS[CYAN]}${SYMBOLS[ARROW]} Escolha uma opção: ${COLORS[NC]}"
        read -r choice
        
        case $choice in
            1)
                sudo systemctl status $SERVICE_NAME --no-pager
                ;;
            2)
                sudo systemctl start $SERVICE_NAME
                msg_success "Serviço iniciado"
                ;;
            3)
                sudo systemctl stop $SERVICE_NAME
                msg_success "Serviço parado"
                ;;
            4)
                sudo systemctl restart $SERVICE_NAME
                msg_success "Serviço reiniciado"
                ;;
            5)
                msg_info "Pressione Ctrl+C para sair dos logs"
                sudo journalctl -u $SERVICE_NAME -f
                ;;
            6)
                if [[ -f "$CONFIG_DIR/config.yml" ]]; then
                    cat "$CONFIG_DIR/config.yml"
                else
                    msg_error "Arquivo de configuração não encontrado"
                fi
                ;;
            7)
                test_connectivity
                ;;
            0)
                return
                ;;
            *)
                msg_error "Opção inválida"
                ;;
        esac
        
        if [[ $choice != 5 ]]; then
            echo ""
            read -p "Pressione ENTER para continuar..."
        fi
    done
}

# Testar conectividade
function test_connectivity() {
    msg_info "Testando conectividade..."
    
    # Verificar se cloudflared está funcionando
    if pgrep -f cloudflared >/dev/null; then
        msg_success "Processo Cloudflared: Rodando"
    else
        msg_error "Processo Cloudflared: Não encontrado"
    fi
    
    # Verificar serviços configurados
    if [[ -f "$CONFIG_DIR/config.yml" ]]; then
        echo ""
        msg_info "Testando serviços configurados:"
        
        while IFS= read -r line; do
            if [[ $line =~ hostname:\ (.+) ]]; then
                hostname="${BASH_REMATCH[1]}"
                printf "   ${COLORS[CYAN]}%s${COLORS[NC]} -> " "$hostname"
                
                if curl -s -o /dev/null -w "%{http_code}" "https://$hostname" | grep -q "200\|301\|302"; then
                    printf "${COLORS[GREEN]}OK${COLORS[NC]}\n"
                else
                    printf "${COLORS[YELLOW]}Verificar${COLORS[NC]}\n"
                fi
            fi
        done < "$CONFIG_DIR/config.yml"
    fi
}

# Processo principal de instalação
function start_installation() {
    local mode="$1"
    
    # Obter configurações
    get_user_inputs "$mode"
    
    # Mostrar resumo
    show_configuration_summary
    
    if ! confirm_action "Iniciar instalação com essas configurações?"; then
        return
    fi
    
    # Processo de instalação
    local total_steps=7
    local current_step=0
    
    show_header
    draw_box "INSTALAÇÃO EM PROGRESSO" "GREEN"
    
    # Etapa 1: Dependências
    ((current_step++))
    msg_step $current_step $total_steps "Instalando dependências"
    install_dependencies
    show_progress $current_step $total_steps "Dependências"
    
    # Etapa 2: Cloudflared
    ((current_step++))
    msg_step $current_step $total_steps "Instalando Cloudflared"
    install_cloudflared
    show_progress $current_step $total_steps "Cloudflared"
    
    # Etapa 3: Login
    ((current_step++))
    msg_step $current_step $total_steps "Configurando acesso ao Cloudflare"
    cloudflared_login
    show_progress $current_step $total_steps "Login"
    
    # Etapa 4: Tunnel
    ((current_step++))
    msg_step $current_step $total_steps "Criando tunnel"
    create_tunnel
    show_progress $current_step $total_steps "Tunnel"
    
    # Etapa 5: Configuração
    ((current_step++))
    msg_step $current_step $total_steps "Configurando serviços"
    create_config
    show_progress $current_step $total_steps "Configuração"
    
    # Etapa 6: DNS
    ((current_step++))
    msg_step $current_step $total_steps "Configurando DNS"
    setup_dns
    show_progress $current_step $total_steps "DNS"
    
    # Etapa 7: Serviço
    ((current_step++))
    msg_step $current_step $total_steps "Instalando serviço"
    install_service
    show_progress $current_step $total_steps "Serviço"
    
    # Mostrar resultado
    show_installation_complete
}

function show_configuration_summary() {
    show_header
    draw_box "RESUMO DA CONFIGURAÇÃO" "YELLOW"
    
    echo ""
    printf "${COLORS[WHITE]}${COLORS[BOLD]}🚇 TUNNEL:${COLORS[NC]} %s\n" "$TUNNEL_NAME"
    echo ""
    printf "${COLORS[WHITE]}${COLORS[BOLD]}🌐 SERVIÇOS CONFIGURADOS:${COLORS[NC]}\n"
    
    for service in "${SERVICES[@]}"; do
        IFS='|' read -r hostname service_url <<< "$service"
        printf "   ${COLORS[CYAN]}%s${COLORS[NC]} -> ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$hostname" "$service_url"
    done
    
    echo ""
}

function show_installation_complete() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    clear_screen
    echo ""
    
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
    
    printf "${COLORS[WHITE]}${COLORS[BOLD]}"
    printf "%20s 🎉 CLOUDFLARED INSTALADO COM SUCESSO! 🎉\n" ""
    printf "${COLORS[NC]}\n"
    
    # Estatísticas
    draw_box "ESTATÍSTICAS DA INSTALAÇÃO" "CYAN"
    printf "${COLORS[CYAN]}   ⏱️  Tempo total: ${COLORS[WHITE]}%02d:%02d${COLORS[NC]}\n" $minutes $seconds
    printf "${COLORS[CYAN]}   🚇 Tunnel ID: ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$TUNNEL_ID"
    printf "${COLORS[CYAN]}   📂 Configuração: ${COLORS[WHITE]}%s${COLORS[NC]}\n" "$CONFIG_DIR/config.yml"
    echo ""
    
    # Serviços configurados
    draw_box "SERVIÇOS CONFIGURADOS" "BLUE"
    for service in "${SERVICES[@]}"; do
        IFS='|' read -r hostname service_url <<< "$service"
        printf "${COLORS[BLUE]}   🌐 ${COLORS[WHITE]}https://%s${COLORS[NC]}\n" "$hostname"
    done
    echo ""
    
    # Comandos úteis
    draw_box "COMANDOS DE GERENCIAMENTO" "PURPLE"
    printf "${COLORS[PURPLE]}   🔧 Ver status: ${COLORS[WHITE]}sudo systemctl status $SERVICE_NAME${COLORS[NC]}\n"
    printf "${COLORS[PURPLE]}   📝 Ver logs: ${COLORS[WHITE]}sudo journalctl -u $SERVICE_NAME -f${COLORS[NC]}\n"
    printf "${COLORS[PURPLE]}   🔄 Reiniciar: ${COLORS[WHITE]}sudo systemctl restart $SERVICE_NAME${COLORS[NC]}\n"
    printf "${COLORS[PURPLE]}   ⚙️ Configuração: ${COLORS[WHITE]}sudo nano $CONFIG_DIR/config.yml${COLORS[NC]}\n"
    echo ""
    
    draw_line "═" 80 "GREEN"
    
    printf "${COLORS[GREEN]}${COLORS[BOLD]}"
    printf "%25s ${SYMBOLS[ROCKET]} INSTALAÇÃO CONCLUÍDA! ${SYMBOLS[ROCKET]}\n" ""
    printf "${COLORS[NC]}\n"
    
    read -p "Pressione ENTER para finalizar..."
}

function configure_existing_installation() {
    if ! command -v cloudflared >/dev/null 2>&1; then
        msg_error "Cloudflared não está instalado! Use a opção 1 ou 2 primeiro."
        read -p "Pressione ENTER para continuar..."
        return
    fi
    
    msg_info "Configurando instalação existente do Cloudflared..."
    # Implementar configuração de instalação existente
    read -p "Pressione ENTER para continuar..."
}

function show_about() {
    show_header
    
    cat << EOF
${COLORS[CYAN]}${COLORS[BOLD]}
╔══════════════════════════════════════════════════════════════════════╗
║                           SOBRE O SCRIPT                            ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  ${SYMBOLS[ROCKET]} Script: Cloudflared Tunnel Installer v$SCRIPT_VERSION                ║
║  ${SYMBOLS[GEAR]} Função: Instalação automática em servidores Linux            ║
║  ${SYMBOLS[CLOUD]} Sistemas suportados:                                         ║
║     • Ubuntu Server (todas as versões)                              ║
║     • DietPi                                                         ║
║     • Debian                                                         ║
║     • CentOS / RHEL                                                  ║
║     • Fedora                                                         ║
║     • Arch Linux                                                     ║
║                                                                      ║
║  ${SYMBOLS[SHIELD]} Recursos:                                                    ║
║     • Interface visual interativa                                   ║
║     • Detecção automática de distribuição                           ║
║     • Suporte a múltiplos serviços                                  ║
║     • Configuração de serviços comuns                               ║
║     • Gerenciamento systemd integrado                               ║
║     • Sistema de logs detalhado                                     ║
║                                                                      ║
║  ${SYMBOLS[LOCK]} Arquiteturas suportadas:                                      ║
║     • x86_64 (Intel/AMD 64-bit)                                     ║
║     • ARM64 (Raspberry Pi 4, etc.)                                  ║
║     • ARMv7 (Raspberry Pi 3, etc.)                                  ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
${COLORS[NC]}
EOF
}

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
     ║                    Versão Linux Edition                       ║
     ║                                                               ║
     ╚═══════════════════════════════════════════════════════════════╝
EOF
    printf "${COLORS[NC]}\n\n"
    
    printf "${COLORS[CYAN]}${SYMBOLS[STAR]} Até a próxima! ${SYMBOLS[STAR]}${COLORS[NC]}\n\n"
}

# Função principal
function main() {
    # Verificar se o terminal suporta cores
    if [[ ! -t 1 ]]; then
        for color in "${!COLORS[@]}"; do
            COLORS[$color]=""
        done
    fi
    
    # Detectar distribuição
    detect_distro
    
    # Verificar se é root
    if [[ $EUID -eq 0 ]]; then
        msg_warn "Executando como root. Alguns comandos serão executados sem sudo."
        SUDO_CMD=""
    else
        SUDO_CMD="sudo"
    fi
    
    # Mostrar menu principal
    show_main_menu
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
