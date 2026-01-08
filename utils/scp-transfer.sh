#!/bin/bash

# Script Avançado para Transferência SCP
# Versão 3.0 - Interface Bonita e Funcional

# Cores e estilos
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'
BOLD='\033[1m'

# Arquivos de configuração
CONFIG_DIR="$HOME/.scp_transfer"
SERVERS_FILE="$CONFIG_DIR/servers"

# Criar diretório de configuração se não existir
mkdir -p "$CONFIG_DIR"
touch "$SERVERS_FILE"

# Detectar distribuição e definir pasta padrão
detect_default_path() {
    if [[ -f /etc/debian_version ]]; then
        if [[ $(whoami) == "root" ]]; then
            DEFAULT_PATH="/root"
        else
            DEFAULT_PATH="/home/$(whoami)"
        fi
    elif [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release; then
        DEFAULT_PATH="/home/$(whoami)"
    else
        # Fallback para outras distribuições
        DEFAULT_PATH="$HOME"
    fi
}

# Função para desenhar bordas bonitas
draw_header_border() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
}

draw_footer_border() {
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

draw_separator() {
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
}

draw_simple_border() {
    echo -e "${BLUE}┌────────────────────────────────────────────────────────────────────────────┐${NC}"
}

draw_simple_footer() {
    echo -e "${BLUE}└────────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Função para texto com borda
bordered_text() {
    local text="$1"
    local color="${2:-$WHITE}"
    echo -e "${CYAN}║${NC} ${color}${text}${NC}"
}

# Função para mostrar header principal
show_header() {
    clear
    echo ""
    draw_header_border
    bordered_text "                    🚀 TRANSFERÊNCIA SCP AVANÇADA 🚀                    " "$BOLD$CYAN"
    bordered_text "                         Versão 3.0 - Interface Bonita                         " "$GRAY"
    draw_separator
    bordered_text "                       Sistema de Transferência de Arquivos                       " "$WHITE"
    bordered_text "                          Com Autocompletar e Servidores                          " "$YELLOW"
    draw_footer_border
    echo ""
}

# Função para mostrar etapas
show_step() {
    local step="$1"
    local total="$2"
    local description="$3"
    
    echo ""
    draw_simple_border
    echo -e "${BLUE}│${NC} ${BOLD}${GREEN}ETAPA $step de $total${NC} ${BLUE}│${NC} ${YELLOW}$description${NC}"
    draw_simple_footer
    echo ""
}

# Função para autocompletar
enable_file_completion() {
    bind 'set completion-ignore-case on'
    bind 'set show-all-if-ambiguous on'
    bind 'set completion-map-case on'
}

# Função para mostrar informações do sistema
show_system_info() {
    local distro="Desconhecida"
    local default_user_path=""
    
    if [[ -f /etc/debian_version ]]; then
        distro="Debian"
        default_user_path="/root (como root) ou /home/usuario"
    elif [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release; then
        distro="Ubuntu"
        default_user_path="/home/usuario"
    fi
    
    echo -e "${CYAN}┌─ Informações do Sistema ─────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}🐧 Distribuição:${NC} $distro"
    echo -e "${CYAN}│${NC} ${BLUE}👤 Usuário atual:${NC} $(whoami)"
    echo -e "${CYAN}│${NC} ${BLUE}📁 Pasta padrão:${NC} $DEFAULT_PATH"
    echo -e "${CYAN}│${NC} ${BLUE}🏠 Pasta home:${NC} $HOME"
    echo -e "${CYAN}└───────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Função para seleção de origem
select_source_interactive() {
    show_step 1 3 "SELEÇÃO DE ARQUIVO/DIRETÓRIO"
    
    show_system_info
    
    echo -e "${YELLOW}📁 Seleção de Origem${NC}"
    echo -e "${GRAY}Navegue usando TAB para autocompletar${NC}"
    echo ""
    
    # Mudar para pasta padrão
    cd "$DEFAULT_PATH" 2>/dev/null || cd "$HOME"
    
    echo -e "${BLUE}📂 Diretório atual: ${BOLD}$(pwd)${NC}"
    echo ""
    echo -e "${CYAN}┌─ Conteúdo do Diretório ──────────────────────────────────────────────────┐${NC}"
    
    # Mostrar conteúdo com cores
    ls -la --color=always | head -10 | while read line; do
        echo -e "${CYAN}│${NC} $line"
    done
    
    echo -e "${CYAN}└───────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    while true; do
        echo -e "${GREEN}📂 Digite o caminho do arquivo/diretório:${NC}"
        echo -e "${GRAY}   (Pressione TAB para autocompletar, Enter vazio para diretório atual)${NC}"
        read -e -p "   🎯 " SOURCE
        
        # Se vazio, usar diretório atual
        if [[ -z "$SOURCE" ]]; then
            SOURCE="$(pwd)"
        fi
        
        # Expandir ~ para home
        SOURCE="${SOURCE/#\~/$HOME}"
        
        # Converter para caminho absoluto se relativo
        if [[ ! "$SOURCE" =~ ^/ ]]; then
            SOURCE="$(pwd)/$SOURCE"
        fi
        
        if [[ -e "$SOURCE" ]]; then
            break
        else
            echo -e "${RED}   ❌ Não encontrado: $SOURCE${NC}"
            echo -e "${YELLOW}   💡 Use TAB para autocompletar${NC}"
            echo ""
        fi
    done
    
    # Verificar se é diretório
    if [[ -d "$SOURCE" ]]; then
        IS_DIRECTORY="true"
        echo -e "${GREEN}   ✅ Diretório selecionado (cópia recursiva)${NC}"
        echo -e "${BLUE}   📊 Tamanho: $(du -sh "$SOURCE" 2>/dev/null | cut -f1)${NC}"
    else
        IS_DIRECTORY="false"
        echo -e "${GREEN}   ✅ Arquivo selecionado${NC}"
        echo -e "${BLUE}   📊 Tamanho: $(ls -lh "$SOURCE" 2>/dev/null | awk '{print $5}')${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Pressione Enter para continuar...${NC}"
    read
}

# Função para salvar servidor
save_server() {
    local server="$1"
    local user="$2"
    local port="$3"
    local key="$4"
    
    if ! grep -q "^$server:" "$SERVERS_FILE"; then
        echo "$server:$user:$port:$key" >> "$SERVERS_FILE"
        echo -e "${GREEN}   💾 Servidor salvo para uso futuro!${NC}"
    fi
}

# Função para listar servidores salvos
list_saved_servers() {
    if [[ ! -s "$SERVERS_FILE" ]]; then
        return 1
    fi
    
    echo -e "${CYAN}┌─ Servidores Salvos ──────────────────────────────────────────────────────┐${NC}"
    
    local i=1
    while IFS=':' read -r server user port key; do
        echo -e "${CYAN}│${NC} ${WHITE}[$i]${NC} ${GREEN}$user@$server${NC}:${YELLOW}$port${NC}"
        if [[ -n "$key" ]]; then
            echo -e "${CYAN}│${NC}     ${BLUE}🔑 Chave: $key${NC}"
        fi
        ((i++))
    done < "$SERVERS_FILE"
    
    echo -e "${CYAN}└───────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    return 0
}

# Função para selecionar servidor salvo
select_saved_server() {
    if ! list_saved_servers; then
        return 1
    fi
    
    local total_servers=$(wc -l < "$SERVERS_FILE")
    
    while true; do
        echo -e "${GREEN}🎯 Selecione o servidor [1-$total_servers] ou [0] para configurar novo:${NC}"
        read -p "   Opção: " choice
        
        if [[ "$choice" == "0" ]]; then
            return 1
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "$total_servers" ]]; then
            local line=$(sed -n "${choice}p" "$SERVERS_FILE")
            IFS=':' read -r SERVER USER_REMOTE PORT SSH_KEY <<< "$line"
            return 0
        else
            echo -e "${RED}   ❌ Opção inválida!${NC}"
        fi
    done
}

# Função para configurar servidor
configure_server() {
    show_step 2 3 "CONFIGURAÇÃO DO SERVIDOR"
    
    echo -e "${YELLOW}🌐 Configuração do Servidor de Destino${NC}"
    echo ""
    
    # Verificar servidores salvos
    if select_saved_server; then
        echo -e "${GREEN}   ✅ Servidor selecionado: $USER_REMOTE@$SERVER:$PORT${NC}"
        echo ""
        echo -e "${CYAN}Pressione Enter para continuar...${NC}"
        read
        return 0
    fi
    
    echo -e "${BLUE}📝 Configurando novo servidor...${NC}"
    echo ""
    
    # Coletar informações do servidor
    echo -e "${GREEN}👤 Usuário remoto:${NC}"
    read -p "   " USER_REMOTE
    
    echo -e "${GREEN}🖥️  Servidor (IP ou hostname):${NC}"
    read -p "   " SERVER
    
    echo -e "${GREEN}🔌 Porta SSH:${NC}"
    read -p "   [22]: " PORT
    PORT=${PORT:-22}
    
    echo ""
    echo -e "${YELLOW}🔑 Configuração de Autenticação${NC}"
    echo -e "${GREEN}🗝️  Caminho para chave SSH (deixe vazio para usar senha):${NC}"
    read -p "   " SSH_KEY
    
    if [[ -n "$SSH_KEY" ]]; then
        SSH_KEY="${SSH_KEY/#\~/$HOME}"
        if [[ ! -f "$SSH_KEY" ]]; then
            echo -e "${YELLOW}   ⚠️ Chave SSH não encontrada, será usada autenticação por senha${NC}"
            SSH_KEY=""
        else
            echo -e "${GREEN}   ✅ Chave SSH encontrada${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}💾 Deseja salvar este servidor para uso futuro?${NC}"
    read -p "   [s/N]: " save_choice
    if [[ "$save_choice" =~ ^[Ss]$ ]]; then
        save_server "$SERVER" "$USER_REMOTE" "$PORT" "$SSH_KEY"
    fi
    
    echo ""
    echo -e "${CYAN}Pressione Enter para continuar...${NC}"
    read
}

# Função para configurar destino
configure_destination() {
    show_step 3 3 "CONFIGURAÇÃO DO DESTINO"
    
    echo -e "${YELLOW}🎯 Configuração do Diretório de Destino${NC}"
    echo ""
    
    echo -e "${GREEN}📂 Diretório de destino no servidor remoto:${NC}"
    echo -e "${GRAY}   (Exemplo: /home/usuario/, /tmp/, /var/www/)${NC}"
    read -p "   [/tmp/]: " TARGET_DIR
    TARGET_DIR=${TARGET_DIR:-/tmp/}
    
    # Garantir que termine com /
    if [[ ! "$TARGET_DIR" =~ /$ ]]; then
        TARGET_DIR="$TARGET_DIR/"
    fi
    
    echo -e "${GREEN}   ✅ Destino configurado: $TARGET_DIR${NC}"
    echo ""
    echo -e "${CYAN}Pressione Enter para continuar...${NC}"
    read
}

# Função para mostrar resumo
show_summary() {
    clear
    echo ""
    draw_header_border
    bordered_text "                           📋 RESUMO DA TRANSFERÊNCIA                           " "$BOLD$YELLOW"
    draw_separator
    bordered_text ""
    bordered_text "📁 Origem:      $SOURCE" "$WHITE"
    bordered_text "🎯 Destino:     $USER_REMOTE@$SERVER:$TARGET_DIR" "$WHITE"
    bordered_text "🔌 Porta:       $PORT" "$WHITE"
    
    if [[ -n "$SSH_KEY" ]]; then
        bordered_text "🔑 Chave SSH:   $SSH_KEY" "$WHITE"
    else
        bordered_text "🔐 Autenticação: Senha" "$WHITE"
    fi
    
    if [[ "$IS_DIRECTORY" == "true" ]]; then
        bordered_text "📦 Modo:        Recursivo (diretório completo)" "$WHITE"
    else
        bordered_text "📄 Modo:        Arquivo único" "$WHITE"
    fi
    
    bordered_text ""
    draw_footer_border
    echo ""
}

# Função para executar transferência
execute_transfer() {
    echo -e "${BLUE}🚀 Preparando transferência...${NC}"
    echo ""
    
    # Construir comando SCP
    local cmd="scp -p"
    
    if [[ "$IS_DIRECTORY" == "true" ]]; then
        cmd="$cmd -r"
    fi
    
    if [[ -n "$SSH_KEY" ]]; then
        cmd="$cmd -i '$SSH_KEY'"
    fi
    
    if [[ "$PORT" != "22" ]]; then
        cmd="$cmd -P $PORT"
    fi
    
    cmd="$cmd '$SOURCE' '$USER_REMOTE@$SERVER:$TARGET_DIR'"
    
    echo -e "${CYAN}┌─ Comando de Execução ────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} $cmd"
    echo -e "${CYAN}└───────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${YELLOW}⏳ Executando transferência...${NC}"
    echo ""
    
    # Executar comando SCP
    if eval "$cmd"; then
        echo ""
        draw_header_border
        bordered_text "                            ✅ TRANSFERÊNCIA CONCLUÍDA!                            " "$BOLD$GREEN"
        bordered_text "                              Arquivos enviados com sucesso                              " "$WHITE"
        draw_footer_border
        echo ""
    else
        echo ""
        draw_header_border
        bordered_text "                             ❌ ERRO NA TRANSFERÊNCIA!                             " "$BOLD$RED"
        bordered_text "                          Verifique as configurações e tente novamente                          " "$WHITE"
        draw_footer_border
        echo ""
        exit 1
    fi
}

# Função principal interativa
interactive_mode() {
    # Detectar pasta padrão
    detect_default_path
    
    show_header
    
    # Habilitar autocompletar
    enable_file_completion
    
    # Executar etapas
    select_source_interactive
    configure_server
    configure_destination
    
    # Mostrar resumo e confirmar
    show_summary
    
    echo -e "${GREEN}🚀 Confirmar e executar transferência?${NC}"
    read -p "   [S/n]: " confirm
    if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
        execute_transfer
    else
        echo -e "${YELLOW}❌ Transferência cancelada pelo usuário${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Pressione Enter para finalizar...${NC}"
    read
}

# Menu principal
main_menu() {
    while true; do
        show_header
        
        echo -e "${WHITE}Selecione uma opção:${NC}"
        echo ""
        echo -e "${GREEN}[1]${NC} 🆕 Nova transferência"
        echo -e "${GREEN}[2]${NC} 📋 Gerenciar servidores salvos"
        echo -e "${GREEN}[3]${NC} 🗑️  Limpar servidores salvos"
        echo -e "${GREEN}[4]${NC} ❌ Sair"
        echo ""
        
        read -p "🎯 Opção: " option
        
        case $option in
            1)
                interactive_mode
                ;;
            2)
                clear
                echo ""
                if ! list_saved_servers; then
                    echo -e "${YELLOW}📝 Nenhum servidor salvo encontrado${NC}"
                else
                    echo -e "${BLUE}💡 Estes servidores podem ser usados nas transferências${NC}"
                fi
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${NC}"
                read
                ;;
            3)
                echo ""
                echo -e "${RED}⚠️  Confirma a limpeza de todos os servidores salvos?${NC}"
                read -p "   [s/N]: " confirm
                if [[ "$confirm" =~ ^[Ss]$ ]]; then
                    > "$SERVERS_FILE"
                    echo -e "${GREEN}✅ Servidores salvos foram limpos!${NC}"
                else
                    echo -e "${BLUE}❌ Operação cancelada${NC}"
                fi
                echo ""
                echo -e "${CYAN}Pressione Enter para continuar...${NC}"
                read
                ;;
            4)
                clear
                echo ""
                draw_header_border
                bordered_text "                               👋 Até logo!                               " "$BOLD$GREEN"
                bordered_text "                        Obrigado por usar o SCP Transfer                        " "$WHITE"
                draw_footer_border
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Variáveis globais
PORT="22"
TARGET_DIR="/tmp/"
IS_DIRECTORY="false"
DEFAULT_PATH=""

# Verificar argumentos
if [[ $# -eq 0 ]]; then
    main_menu
else
    echo "Use sem argumentos para modo interativo"
    echo "Exemplo: ./scp_transfer.sh"
fi
