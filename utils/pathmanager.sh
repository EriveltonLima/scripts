#!/bin/bash

# PathManager - Script para gerenciar scripts no PATH
# Facilita a instalação e remoção de scripts personalizados
# Versão: 2.0 - Com auto-instalação e interface interativa

set -e

# Cores para interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Diretórios padrão
SYSTEM_BIN="/usr/local/bin"
USER_BIN="$HOME/.local/bin"
BACKUP_DIR="$HOME/.pathmanager_backup"
SCRIPT_NAME="pathmanager"

# Arquivo de controle para primeira execução
FIRST_RUN_FILE="$HOME/.pathmanager_installed"

# Funções de log
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Função para pausar e aguardar entrada do usuário
pause() {
    echo -e "\n${CYAN}Pressione ENTER para continuar...${NC}"
    read
}

# Função para auto-instalação na primeira execução
auto_install() {
    if [ -f "$FIRST_RUN_FILE" ]; then
        return 0
    fi
    
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                    PRIMEIRA EXECUÇÃO DO PATHMANAGER                     ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${YELLOW}Este é o primeiro uso do PathManager!${NC}"
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} Para usar o comando 'pathmanager' de qualquer lugar do sistema,"
    echo -e "${WHITE}║${NC} preciso me instalar no PATH."
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Opções de instalação:${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}1)${NC} Instalar para todos os usuários (requer sudo)"
    echo -e "${WHITE}║${NC}    Localização: $SYSTEM_BIN"
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}2)${NC} Instalar apenas para seu usuário (recomendado)"
    echo -e "${WHITE}║${NC}    Localização: $USER_BIN"
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}3)${NC} Pular instalação (usar apenas ./pathmanager.sh)"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${CYAN}Escolha uma opção (1-3): ${NC}"
    read -n 1 choice
    echo
    
    case $choice in
        1)
            echo -e "\n${YELLOW}Instalando para todos os usuários...${NC}"
            if sudo cp "$0" "$SYSTEM_BIN/$SCRIPT_NAME" && sudo chmod +x "$SYSTEM_BIN/$SCRIPT_NAME"; then
                success "PathManager instalado em $SYSTEM_BIN/$SCRIPT_NAME"
                success "Agora você pode usar 'pathmanager' de qualquer lugar!"
                touch "$FIRST_RUN_FILE"
            else
                error "Falha na instalação. Continuando sem instalar..."
            fi
            ;;
        2)
            echo -e "\n${YELLOW}Instalando para seu usuário...${NC}"
            setup_directories
            if cp "$0" "$USER_BIN/$SCRIPT_NAME" && chmod +x "$USER_BIN/$SCRIPT_NAME"; then
                success "PathManager instalado em $USER_BIN/$SCRIPT_NAME"
                if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
                    echo "export PATH=\$PATH:$USER_BIN" >> ~/.bashrc
                    warn "Adicionado $USER_BIN ao PATH no ~/.bashrc"
                    warn "Execute 'source ~/.bashrc' ou abra um novo terminal"
                fi
                success "Agora você pode usar 'pathmanager' de qualquer lugar!"
                touch "$FIRST_RUN_FILE"
            else
                error "Falha na instalação. Continuando sem instalar..."
            fi
            ;;
        3)
            echo -e "\n${YELLOW}Pulando instalação...${NC}"
            warn "Use './pathmanager.sh' para executar o script"
            touch "$FIRST_RUN_FILE"
            ;;
        *)
            warn "Opção inválida. Pulando instalação..."
            touch "$FIRST_RUN_FILE"
            ;;
    esac
    
    pause
}

# Função para verificar se é root
is_root() {
    [ "$EUID" -eq 0 ]
}

# Função para criar diretórios necessários
setup_directories() {
    if ! is_root; then
        mkdir -p "$USER_BIN"
        mkdir -p "$BACKUP_DIR"
    fi
}

# Interface interativa para adicionar scripts
interactive_add() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                        ADICIONAR SCRIPT AO PATH                         ${WHITE}║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Listar arquivos .sh no diretório atual
    echo -e "\n${CYAN}Scripts disponíveis no diretório atual:${NC}"
    local scripts=($(find . -maxdepth 1 -name "*.sh" -type f | sort))
    
    if [ ${#scripts[@]} -eq 0 ]; then
        warn "Nenhum script .sh encontrado no diretório atual"
        echo -e "\n${CYAN}Digite o caminho completo do script: ${NC}"
        read script_path
    else
        echo -e "${GREEN}0)${NC} Digitar caminho manualmente"
        for i in "${!scripts[@]}"; do
            local script=${scripts[$i]}
            local name=$(basename "$script")
            local size=$(du -h "$script" 2>/dev/null | cut -f1 || echo "?")
            echo -e "${GREEN}$((i+1)))${NC} $name ${YELLOW}($size)${NC}"
        done
        
        echo -e "\n${CYAN}Escolha um script (0-${#scripts[@]}): ${NC}"
        read -n 1 choice
        echo
        
        if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 0 ] && [ $choice -le ${#scripts[@]} ]; then
            if [ $choice -eq 0 ]; then
                echo -e "${CYAN}Digite o caminho completo do script: ${NC}"
                read script_path
            else
                script_path=${scripts[$((choice-1))]}
            fi
        else
            error "Opção inválida"
            return 1
        fi
    fi
    
    if [ ! -f "$script_path" ]; then
        error "Arquivo não encontrado: $script_path"
        return 1
    fi
    
    # Mostrar informações do script
    echo -e "\n${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                           INFORMAÇÕES DO SCRIPT                         ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Arquivo:${NC} $(basename "$script_path")"
    echo -e "${WHITE}║${NC} ${CYAN}Caminho:${NC} $script_path"
    echo -e "${WHITE}║${NC} ${CYAN}Tamanho:${NC} $(du -h "$script_path" 2>/dev/null | cut -f1 || echo "desconhecido")"
    echo -e "${WHITE}║${NC} ${CYAN}Modificado:${NC} $(date -r "$script_path" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "desconhecido")"
    
    # Verificar shebang
    local first_line=$(head -1 "$script_path" 2>/dev/null || echo "")
    if [[ $first_line =~ ^#! ]]; then
        echo -e "${WHITE}║${NC} ${CYAN}Shebang:${NC} ${GREEN}✓${NC} $first_line"
    else
        echo -e "${WHITE}║${NC} ${CYAN}Shebang:${NC} ${YELLOW}!${NC} Será adicionado #!/bin/bash"
    fi
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Definir nome do comando
    local default_name=$(basename "$script_path" .sh)
    echo -e "\n${CYAN}Nome do comando (padrão: $default_name): ${NC}"
    read custom_name
    local script_name=${custom_name:-$default_name}
    
    # Escolher local de instalação
    echo -e "\n${CYAN}Local de instalação:${NC}"
    echo -e "${GREEN}1)${NC} Sistema ($SYSTEM_BIN) - Todos os usuários"
    echo -e "${GREEN}2)${NC} Usuário ($USER_BIN) - Apenas você ${YELLOW}(recomendado)${NC}"
    echo -e "\n${CYAN}Escolha (1-2): ${NC}"
    read -n 1 install_choice
    echo
    
    local target_dir
    local needs_sudo=false
    
    case $install_choice in
        1)
            target_dir="$SYSTEM_BIN"
            needs_sudo=true
            ;;
        2|*)
            target_dir="$USER_BIN"
            setup_directories
            ;;
    esac
    
    local target_file="$target_dir/$script_name"
    
    # Verificar se já existe
    if [ -f "$target_file" ]; then
        echo -e "\n${YELLOW}⚠️  Script '$script_name' já existe em $target_file${NC}"
        echo -e "${CYAN}Sobrescrever? (s/N): ${NC}"
        read -n 1 confirm
        echo
        if [[ ! $confirm =~ ^[sS]$ ]]; then
            warn "Operação cancelada"
            return 1
        fi
        
        # Fazer backup
        local backup_file="$BACKUP_DIR/${script_name}.backup.$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        cp "$target_file" "$backup_file" 2>/dev/null && log "Backup salvo: $backup_file"
    fi
    
    # Confirmar instalação
    echo -e "\n${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                            CONFIRMAR INSTALAÇÃO                         ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Origem:${NC} $script_path"
    echo -e "${WHITE}║${NC} ${CYAN}Destino:${NC} $target_file"
    echo -e "${WHITE}║${NC} ${CYAN}Comando:${NC} $script_name"
    echo -e "${WHITE}║${NC} ${CYAN}Sudo:${NC} $([ "$needs_sudo" = true ] && echo "${RED}Sim${NC}" || echo "${GREEN}Não${NC}")"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}Confirmar instalação? (S/n): ${NC}"
    read -n 1 final_confirm
    echo
    
    if [[ $final_confirm =~ ^[nN]$ ]]; then
        warn "Instalação cancelada"
        return 1
    fi
    
    # Executar instalação
    echo -e "\n${YELLOW}Instalando...${NC}"
    
    if [ "$needs_sudo" = true ]; then
        if sudo cp "$script_path" "$target_file" && sudo chmod +x "$target_file"; then
            success "Script instalado com sucesso!"
        else
            error "Falha na instalação"
            return 1
        fi
    else
        if cp "$script_path" "$target_file" && chmod +x "$target_file"; then
            success "Script instalado com sucesso!"
        else
            error "Falha na instalação"
            return 1
        fi
    fi
    
    # Verificar e corrigir shebang se necessário
    if ! head -1 "$target_file" | grep -q "^#!"; then
        warn "Adicionando shebang #!/bin/bash"
        if [ "$needs_sudo" = true ]; then
            sudo sed -i '1i#!/bin/bash' "$target_file"
        else
            sed -i '1i#!/bin/bash' "$target_file"
        fi
    fi
    
    # Verificar se está acessível
    echo -e "\n${CYAN}Testando acessibilidade...${NC}"
    if command -v "$script_name" >/dev/null 2>&1; then
        success "✓ Script '$script_name' está acessível no PATH!"
        info "Execute: $script_name"
    else
        warn "Script pode não estar acessível imediatamente"
        if [ "$target_dir" = "$USER_BIN" ] && [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
            warn "Execute 'source ~/.bashrc' ou abra um novo terminal"
        fi
    fi
    
    pause
}

# Interface interativa para remover scripts
interactive_remove() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                        REMOVER SCRIPT DO PATH                           ${WHITE}║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Listar scripts disponíveis
    local scripts=()
    local paths=()
    
    echo -e "\n${CYAN}Scripts instalados:${NC}"
    
    local count=0
    for dir in "$SYSTEM_BIN" "$USER_BIN"; do
        if [ -d "$dir" ]; then
            for script in "$dir"/*; do
                if [ -f "$script" ] && [ -x "$script" ]; then
                    local name=$(basename "$script")
                    local size=$(du -h "$script" 2>/dev/null | cut -f1 || echo "?")
                    local location=$([ "$dir" = "$SYSTEM_BIN" ] && echo "Sistema" || echo "Usuário")
                    
                    scripts+=("$name")
                    paths+=("$script")
                    count=$((count + 1))
                    
                    echo -e "${GREEN}$count)${NC} $name ${YELLOW}($size)${NC} - ${BLUE}$location${NC}"
                fi
            done
        fi
    done
    
    if [ $count -eq 0 ]; then
        warn "Nenhum script personalizado encontrado"
        pause
        return 1
    fi
    
    echo -e "${GREEN}0)${NC} Cancelar"
    echo -e "\n${CYAN}Escolha um script para remover (0-$count): ${NC}"
    read choice
    
    if [[ ! $choice =~ ^[0-9]+$ ]] || [ $choice -lt 0 ] || [ $choice -gt $count ]; then
        error "Opção inválida"
        return 1
    fi
    
    if [ $choice -eq 0 ]; then
        info "Operação cancelada"
        return 0
    fi
    
    local script_name=${scripts[$((choice-1))]}
    local script_path=${paths[$((choice-1))]}
    
    # Mostrar informações e confirmar
    echo -e "\n${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                           CONFIRMAR REMOÇÃO                             ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Script:${NC} $script_name"
    echo -e "${WHITE}║${NC} ${CYAN}Caminho:${NC} $script_path"
    echo -e "${WHITE}║${NC} ${CYAN}Tamanho:${NC} $(du -h "$script_path" 2>/dev/null | cut -f1 || echo "desconhecido")"
    echo -e "${WHITE}║${NC} ${CYAN}Backup:${NC} Será criado automaticamente"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${RED}Confirmar remoção de '$script_name'? (s/N): ${NC}"
    read -n 1 confirm
    echo
    
    if [[ ! $confirm =~ ^[sS]$ ]]; then
        warn "Remoção cancelada"
        return 1
    fi
    
    # Fazer backup e remover
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/${script_name}.removed.$(date +%Y%m%d_%H%M%S)"
    
    if cp "$script_path" "$backup_file"; then
        log "Backup criado: $backup_file"
        
        if [[ "$script_path" == "$SYSTEM_BIN"* ]]; then
            sudo rm "$script_path" && success "Script '$script_name' removido do PATH"
        else
            rm "$script_path" && success "Script '$script_name' removido do PATH"
        fi
    else
        error "Falha ao criar backup"
        return 1
    fi
    
    pause
}

# Menu principal interativo
interactive_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║${CYAN}                              PATHMANAGER                               ${WHITE}║${NC}"
        echo -e "${WHITE}║${YELLOW}                    Gerenciador de Scripts no PATH                      ${WHITE}║${NC}"
        echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}1)${NC} ${CYAN}Adicionar script ao PATH${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}2)${NC} ${CYAN}Remover script do PATH${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}3)${NC} ${CYAN}Listar scripts instalados${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}4)${NC} ${CYAN}Verificar configuração do PATH${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}5)${NC} ${CYAN}Fazer backup dos scripts${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}6)${NC} ${CYAN}Limpar scripts quebrados${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}7)${NC} ${CYAN}Mostrar ajuda${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}0)${NC} ${CYAN}Sair${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        
        echo -e "\n${CYAN}Escolha uma opção (0-7): ${NC}"
        read -n 1 choice
        echo
        
        case $choice in
            1) interactive_add ;;
            2) interactive_remove ;;
            3) list_scripts; pause ;;
            4) check_path; pause ;;
            5) backup_scripts; pause ;;
            6) clean_broken; pause ;;
            7) show_help; pause ;;
            0) 
                echo -e "\n${GREEN}Obrigado por usar o PathManager!${NC}"
                exit 0
                ;;
            *)
                error "Opção inválida: $choice"
                sleep 1
                ;;
        esac
    done
}

# Função para mostrar ajuda (mantida do original)
show_help() {
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN} PATHMANAGER ${WHITE}║${NC}"
    echo -e "${WHITE}║${YELLOW} Gerenciador de Scripts no PATH ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Uso:${NC} pathmanager [opção] [arquivo]"
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Opções:${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}add${NC} - Adicionar script ao PATH"
    echo -e "${WHITE}║${NC} ${CYAN}remove${NC} - Remover script do PATH"
    echo -e "${WHITE}║${NC} ${CYAN}list${NC} - Listar scripts instalados"
    echo -e "${WHITE}║${NC} ${CYAN}backup${NC} - Fazer backup dos scripts"
    echo -e "${WHITE}║${NC} ${CYAN}restore${NC} - Restaurar backup"
    echo -e "${WHITE}║${NC} ${CYAN}check${NC} - Verificar PATH"
    echo -e "${WHITE}║${NC} ${CYAN}clean${NC} - Limpar scripts quebrados"
    echo -e "${WHITE}║${NC} ${CYAN}interactive${NC} - Menu interativo"
    echo -e "${WHITE}║${NC} ${CYAN}help${NC} - Mostrar esta ajuda"
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Exemplos:${NC}"
    echo -e "${WHITE}║${NC} pathmanager add meu-script.sh"
    echo -e "${WHITE}║${NC} pathmanager remove meu-script"
    echo -e "${WHITE}║${NC} pathmanager interactive"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# [Manter todas as outras funções do script original: add_script, remove_script, list_scripts, check_path, backup_scripts, clean_broken]

# Função para adicionar script ao PATH (mantida do original)
add_script() {
    local script_file="$1"
    
    if [ ! -f "$script_file" ]; then
        error "Arquivo não encontrado: $script_file"
        return 1
    fi
    
    local script_name=$(basename "$script_file" .sh)
    local target_dir
    local target_file
    
    if is_root; then
        target_dir="$SYSTEM_BIN"
        target_file="$SYSTEM_BIN/$script_name"
    else
        setup_directories
        target_dir="$USER_BIN"
        target_file="$USER_BIN/$script_name"
    fi
    
    if [ -f "$target_file" ]; then
        echo -e "${YELLOW}Script '$script_name' já existe. Sobrescrever? (s/N): ${NC}"
        read -n 1 confirm
        echo
        if [[ ! $confirm =~ ^[sS]$ ]]; then
            warn "Operação cancelada"
            return 1
        fi
        cp "$target_file" "$BACKUP_DIR/${script_name}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi
    
    log "Copiando $script_file para $target_file"
    cp "$script_file" "$target_file"
    chmod +x "$target_file"
    
    if ! head -1 "$target_file" | grep -q "^#!"; then
        warn "Script não possui shebang. Adicionando #!/bin/bash"
        sed -i '1i#!/bin/bash' "$target_file"
    fi
    
    success "Script '$script_name' adicionado ao PATH com sucesso!"
    log "Agora você pode executar: $script_name"
    
    if command -v "$script_name" >/dev/null 2>&1; then
        success "Script está acessível no PATH"
    else
        warn "Script pode não estar acessível. Reinicie o terminal ou execute 'source ~/.bashrc'"
    fi
}

# [Manter as outras funções: remove_script, list_scripts, check_path, backup_scripts, clean_broken]

# Função para remover script do PATH (mantida do original)
remove_script() {
    local script_name="$1"
    local found=false
    local script_path=""
    
    for dir in "$SYSTEM_BIN" "$USER_BIN"; do
        if [ -f "$dir/$script_name" ]; then
            script_path="$dir/$script_name"
            found=true
            break
        fi
    done
    
    if [ "$found" = false ]; then
        error "Script '$script_name' não encontrado no PATH"
        return 1
    fi
    
    echo -e "${YELLOW}Remover '$script_name' de $script_path? (s/N): ${NC}"
    read -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[sS]$ ]]; then
        warn "Operação cancelada"
        return 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    cp "$script_path" "$BACKUP_DIR/${script_name}.removed.$(date +%Y%m%d_%H%M%S)"
    rm "$script_path"
    success "Script '$script_name' removido do PATH"
    log "Backup salvo em $BACKUP_DIR"
}

# Função para listar scripts instalados (mantida do original)
list_scripts() {
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN} SCRIPTS NO PATH ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    local found=false
    
    if [ -d "$SYSTEM_BIN" ]; then
        echo -e "${WHITE}║${NC} ${CYAN}Scripts do Sistema ($SYSTEM_BIN):${NC}"
        for script in "$SYSTEM_BIN"/*; do
            if [ -f "$script" ] && [ -x "$script" ]; then
                local name=$(basename "$script")
                local size=$(du -h "$script" | cut -f1)
                local date=$(date -r "$script" "+%Y-%m-%d %H:%M")
                echo -e "${WHITE}║${NC} ${GREEN}$name${NC} (${YELLOW}$size${NC}) - $date"
                found=true
            fi
        done
    fi
    
    if [ -d "$USER_BIN" ]; then
        echo -e "${WHITE}║${NC} ${CYAN}Scripts do Usuário ($USER_BIN):${NC}"
        for script in "$USER_BIN"/*; do
            if [ -f "$script" ] && [ -x "$script" ]; then
                local name=$(basename "$script")
                local size=$(du -h "$script" | cut -f1)
                local date=$(date -r "$script" "+%Y-%m-%d %H:%M")
                echo -e "${WHITE}║${NC} ${GREEN}$name${NC} (${YELLOW}$size${NC}) - $date"
                found=true
            fi
        done
    fi
    
    if [ "$found" = false ]; then
        echo -e "${WHITE}║${NC} ${YELLOW}Nenhum script personalizado encontrado${NC}"
    fi
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# [Manter as outras funções: check_path, backup_scripts, clean_broken]

# Função para verificar PATH (mantida do original)
check_path() {
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN} VERIFICAÇÃO DO PATH ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}PATH atual:${NC}"
    IFS=':' read -ra ADDR <<< "$PATH"
    for dir in "${ADDR[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "${WHITE}║${NC} ${GREEN}✓${NC} $dir"
        else
            echo -e "${WHITE}║${NC} ${RED}✗${NC} $dir ${RED}(não existe)${NC}"
        fi
    done
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Diretórios recomendados:${NC}"
    if [[ ":$PATH:" == *":$SYSTEM_BIN:"* ]]; then
        echo -e "${WHITE}║${NC} ${GREEN}✓${NC} $SYSTEM_BIN (sistema)"
    else
        echo -e "${WHITE}║${NC} ${YELLOW}!${NC} $SYSTEM_BIN (sistema) - não está no PATH"
    fi
    if [[ ":$PATH:" == *":$USER_BIN:"* ]]; then
        echo -e "${WHITE}║${NC} ${GREEN}✓${NC} $USER_BIN (usuário)"
    else
        echo -e "${WHITE}║${NC} ${YELLOW}!${NC} $USER_BIN (usuário) - não está no PATH"
    fi
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Função para fazer backup (mantida do original)
backup_scripts() {
    local backup_file="$BACKUP_DIR/pathmanager_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    mkdir -p "$BACKUP_DIR"
    log "Criando backup dos scripts..."
    
    local temp_list=$(mktemp)
    
    if [ -d "$SYSTEM_BIN" ] && [ -r "$SYSTEM_BIN" ]; then
        find "$SYSTEM_BIN" -type f -executable >> "$temp_list" 2>/dev/null || true
    fi
    
    if [ -d "$USER_BIN" ]; then
        find "$USER_BIN" -type f -executable >> "$temp_list" 2>/dev/null || true
    fi
    
    if [ -s "$temp_list" ]; then
        tar -czf "$backup_file" -T "$temp_list" 2>/dev/null
        success "Backup criado: $backup_file"
    else
        warn "Nenhum script encontrado para backup"
    fi
    
    rm -f "$temp_list"
}

# Função para limpar scripts quebrados (mantida do original)
clean_broken() {
    log "Verificando scripts quebrados..."
    local cleaned=0
    
    for dir in "$SYSTEM_BIN" "$USER_BIN"; do
        if [ -d "$dir" ]; then
            for script in "$dir"/*; do
                if [ -f "$script" ] && [ -x "$script" ]; then
                    if ! "$script" --help >/dev/null 2>&1 && ! "$script" -h >/dev/null 2>&1; then
                        local name=$(basename "$script")
                        echo -e "${YELLOW}Script possivelmente quebrado: $name${NC}"
                        echo -e "Remover? (s/N): "
                        read -n 1 confirm
                        echo
                        if [[ $confirm =~ ^[sS]$ ]]; then
                            cp "$script" "$BACKUP_DIR/${name}.broken.$(date +%Y%m%d_%H%M%S)"
                            rm "$script"
                            cleaned=$((cleaned + 1))
                            log "Removido: $name"
                        fi
                    fi
                fi
            done
        fi
    done
    
    if [ $cleaned -eq 0 ]; then
        success "Nenhum script quebrado encontrado"
    else
        success "Removidos $cleaned scripts quebrados"
    fi
}

# Função principal
main() {
    # Verificar primeira execução e auto-instalar se necessário
    auto_install
    
    case "${1:-interactive}" in
        "add")
            if [ -z "$2" ]; then
                error "Especifique o arquivo do script"
                echo "Uso: pathmanager add script.sh"
                exit 1
            fi
            add_script "$2"
            ;;
        "remove")
            if [ -z "$2" ]; then
                error "Especifique o nome do script"
                echo "Uso: pathmanager remove nome-do-script"
                exit 1
            fi
            remove_script "$2"
            ;;
        "list")
            list_scripts
            ;;
        "check")
            check_path
            ;;
        "backup")
            backup_scripts
            ;;
        "clean")
            clean_broken
            ;;
        "interactive"|"")
            interactive_menu
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Opção inválida: $1"
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
