#!/bin/bash

# PathManager - Script para gerenciar scripts no PATH
# Facilita a instalação e remoção de scripts personalizados
# Versão: 1.0

set -e

# Cores para interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Diretórios padrão
SYSTEM_BIN="/usr/local/bin"
USER_BIN="$HOME/.local/bin"
BACKUP_DIR="$HOME/.pathmanager_backup"

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

# Função para mostrar ajuda
show_help() {
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                              PATHMANAGER                                   ${WHITE}║${NC}"
    echo -e "${WHITE}║${YELLOW}                    Gerenciador de Scripts no PATH                        ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Uso:${NC} pathmanager [opção] [arquivo]"
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Opções:${NC}"
    echo -e "${WHITE}║${NC}   ${CYAN}add${NC}      - Adicionar script ao PATH"
    echo -e "${WHITE}║${NC}   ${CYAN}remove${NC}   - Remover script do PATH"
    echo -e "${WHITE}║${NC}   ${CYAN}list${NC}     - Listar scripts instalados"
    echo -e "${WHITE}║${NC}   ${CYAN}backup${NC}   - Fazer backup dos scripts"
    echo -e "${WHITE}║${NC}   ${CYAN}restore${NC}  - Restaurar backup"
    echo -e "${WHITE}║${NC}   ${CYAN}check${NC}    - Verificar PATH"
    echo -e "${WHITE}║${NC}   ${CYAN}clean${NC}    - Limpar scripts quebrados"
    echo -e "${WHITE}║${NC}   ${CYAN}help${NC}     - Mostrar esta ajuda"
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Exemplos:${NC}"
    echo -e "${WHITE}║${NC}   pathmanager add meu-script.sh"
    echo -e "${WHITE}║${NC}   pathmanager remove meu-script"
    echo -e "${WHITE}║${NC}   pathmanager list"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
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
        
        # Adicionar ~/.local/bin ao PATH se não estiver
        if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
            echo "export PATH=\$PATH:$USER_BIN" >> ~/.bashrc
            warn "Adicionado $USER_BIN ao PATH. Execute 'source ~/.bashrc' ou reinicie o terminal"
        fi
    fi
}

# Função para adicionar script ao PATH
add_script() {
    local script_file="$1"
    
    # Verificar se arquivo existe
    if [ ! -f "$script_file" ]; then
        error "Arquivo não encontrado: $script_file"
        return 1
    fi
    
    # Obter nome base do arquivo
    local script_name=$(basename "$script_file" .sh)
    
    # Determinar diretório de destino
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
    
    # Verificar se já existe
    if [ -f "$target_file" ]; then
        echo -e "${YELLOW}Script '$script_name' já existe. Sobrescrever? (s/N): ${NC}"
        read -n 1 confirm
        echo
        if [[ ! $confirm =~ ^[sS]$ ]]; then
            warn "Operação cancelada"
            return 1
        fi
        
        # Fazer backup do arquivo existente
        cp "$target_file" "$BACKUP_DIR/${script_name}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi
    
    # Copiar arquivo
    log "Copiando $script_file para $target_file"
    cp "$script_file" "$target_file"
    
    # Dar permissão de execução
    chmod +x "$target_file"
    
    # Verificar se tem shebang
    if ! head -1 "$target_file" | grep -q "^#!"; then
        warn "Script não possui shebang. Adicionando #!/bin/bash"
        sed -i '1i#!/bin/bash' "$target_file"
    fi
    
    success "Script '$script_name' adicionado ao PATH com sucesso!"
    log "Agora você pode executar: $script_name"
    
    # Testar se está acessível
    if command -v "$script_name" >/dev/null 2>&1; then
        success "Script está acessível no PATH"
    else
        warn "Script pode não estar acessível. Reinicie o terminal ou execute 'source ~/.bashrc'"
    fi
}

# Função para remover script do PATH
remove_script() {
    local script_name="$1"
    
    # Procurar script nos diretórios
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
    
    # Confirmar remoção
    echo -e "${YELLOW}Remover '$script_name' de $script_path? (s/N): ${NC}"
    read -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[sS]$ ]]; then
        warn "Operação cancelada"
        return 1
    fi
    
    # Fazer backup antes de remover
    mkdir -p "$BACKUP_DIR"
    cp "$script_path" "$BACKUP_DIR/${script_name}.removed.$(date +%Y%m%d_%H%M%S)"
    
    # Remover arquivo
    rm "$script_path"
    
    success "Script '$script_name' removido do PATH"
    log "Backup salvo em $BACKUP_DIR"
}

# Função para listar scripts instalados
list_scripts() {
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                           SCRIPTS NO PATH                                  ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    
    local found=false
    
    # Listar scripts do sistema
    if [ -d "$SYSTEM_BIN" ]; then
        echo -e "${WHITE}║${NC} ${CYAN}Scripts do Sistema ($SYSTEM_BIN):${NC}"
        for script in "$SYSTEM_BIN"/*; do
            if [ -f "$script" ] && [ -x "$script" ]; then
                local name=$(basename "$script")
                local size=$(du -h "$script" | cut -f1)
                local date=$(date -r "$script" "+%Y-%m-%d %H:%M")
                echo -e "${WHITE}║${NC}   ${GREEN}$name${NC} (${YELLOW}$size${NC}) - $date"
                found=true
            fi
        done
    fi
    
    # Listar scripts do usuário
    if [ -d "$USER_BIN" ]; then
        echo -e "${WHITE}║${NC} ${CYAN}Scripts do Usuário ($USER_BIN):${NC}"
        for script in "$USER_BIN"/*; do
            if [ -f "$script" ] && [ -x "$script" ]; then
                local name=$(basename "$script")
                local size=$(du -h "$script" | cut -f1)
                local date=$(date -r "$script" "+%Y-%m-%d %H:%M")
                echo -e "${WHITE}║${NC}   ${GREEN}$name${NC} (${YELLOW}$size${NC}) - $date"
                found=true
            fi
        done
    fi
    
    if [ "$found" = false ]; then
        echo -e "${WHITE}║${NC} ${YELLOW}Nenhum script personalizado encontrado${NC}"
    fi
    
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Função para verificar PATH
check_path() {
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${CYAN}                            VERIFICAÇÃO DO PATH                             ${WHITE}║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    
    echo -e "${WHITE}║${NC} ${CYAN}PATH atual:${NC}"
    IFS=':' read -ra ADDR <<< "$PATH"
    for dir in "${ADDR[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "${WHITE}║${NC}   ${GREEN}✓${NC} $dir"
        else
            echo -e "${WHITE}║${NC}   ${RED}✗${NC} $dir ${RED}(não existe)${NC}"
        fi
    done
    
    echo -e "${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${CYAN}Diretórios recomendados:${NC}"
    
    if [[ ":$PATH:" == *":$SYSTEM_BIN:"* ]]; then
        echo -e "${WHITE}║${NC}   ${GREEN}✓${NC} $SYSTEM_BIN (sistema)"
    else
        echo -e "${WHITE}║${NC}   ${YELLOW}!${NC} $SYSTEM_BIN (sistema) - não está no PATH"
    fi
    
    if [[ ":$PATH:" == *":$USER_BIN:"* ]]; then
        echo -e "${WHITE}║${NC}   ${GREEN}✓${NC} $USER_BIN (usuário)"
    else
        echo -e "${WHITE}║${NC}   ${YELLOW}!${NC} $USER_BIN (usuário) - não está no PATH"
    fi
    
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Função para fazer backup
backup_scripts() {
    local backup_file="$BACKUP_DIR/pathmanager_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    log "Criando backup dos scripts..."
    
    # Criar arquivo temporário com lista de scripts
    local temp_list=$(mktemp)
    
    # Adicionar scripts do sistema (se acessível)
    if [ -d "$SYSTEM_BIN" ] && [ -r "$SYSTEM_BIN" ]; then
        find "$SYSTEM_BIN" -type f -executable >> "$temp_list" 2>/dev/null || true
    fi
    
    # Adicionar scripts do usuário
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

# Função para limpar scripts quebrados
clean_broken() {
    log "Verificando scripts quebrados..."
    
    local cleaned=0
    
    for dir in "$SYSTEM_BIN" "$USER_BIN"; do
        if [ -d "$dir" ]; then
            for script in "$dir"/*; do
                if [ -f "$script" ] && [ -x "$script" ]; then
                    # Verificar se o script está realmente executável
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
    case "${1:-help}" in
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
