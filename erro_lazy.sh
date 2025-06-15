#!/bin/bash

# Script para resolver problemas de upstream no Git/LazyGit
# Autor: Script automatizado para correção de upstream

echo "=== Corretor de Problemas de Upstream Git/LazyGit ==="
echo

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se estamos em um repositório Git
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Este diretório não é um repositório Git!"
        echo "Execute este script dentro de um repositório Git."
        exit 1
    fi
    log_success "Repositório Git detectado"
}

# Verificar status atual do repositório
check_repo_status() {
    log_info "Verificando status do repositório..."
    
    # Verificar se há commits
    if ! git log --oneline > /dev/null 2>&1; then
        echo "📊 Status: Repositório sem commits"
        return 1
    fi
    
    # Verificar branch atual
    current_branch=$(git branch --show-current 2>/dev/null)
    if [[ -z "$current_branch" ]]; then
        echo "📊 Status: HEAD desanexado (detached HEAD)"
        return 2
    fi
    
    # Verificar se há upstream configurado
    upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [[ -z "$upstream" ]]; then
        echo "📊 Status: Branch '$current_branch' sem upstream configurado"
        return 3
    fi
    
    log_success "Repositório está configurado corretamente"
    echo "   Branch atual: $current_branch"
    echo "   Upstream: $upstream"
    return 0
}

# Criar commit inicial se necessário
create_initial_commit() {
    log_info "Criando commit inicial..."
    
    # Verificar se há arquivos para commit
    if [[ -z "$(git status --porcelain)" ]]; then
        # Criar README se não existir
        if [[ ! -f README.md ]]; then
            echo "# $(basename $(pwd))" > README.md
            echo "" >> README.md
            echo "Repositório criado automaticamente." >> README.md
            git add README.md
        else
            # Adicionar todos os arquivos
            git add .
        fi
    else
        git add .
    fi
    
    # Fazer commit
    git commit -m "Initial commit" > /dev/null 2>&1
    log_success "Commit inicial criado"
}

# Resolver HEAD desanexado
fix_detached_head() {
    log_info "Resolvendo HEAD desanexado..."
    
    # Perguntar qual branch criar/usar
    echo "Opções para resolver HEAD desanexado:"
    echo "1) Criar branch 'main'"
    echo "2) Criar branch 'master'"
    echo "3) Criar branch personalizada"
    echo "4) Voltar para branch existente"
    
    read -p "Escolha uma opção (1-4) [1]: " option
    option=${option:-1}
    
    case $option in
        1)
            git checkout -b main > /dev/null 2>&1
            log_success "Branch 'main' criada e ativada"
            ;;
        2)
            git checkout -b master > /dev/null 2>&1
            log_success "Branch 'master' criada e ativada"
            ;;
        3)
            read -p "Digite o nome da nova branch: " branch_name
            if [[ -n "$branch_name" ]]; then
                git checkout -b "$branch_name" > /dev/null 2>&1
                log_success "Branch '$branch_name' criada e ativada"
            else
                log_error "Nome da branch não pode estar vazio"
                return 1
            fi
            ;;
        4)
            echo "Branches disponíveis:"
            git branch -a
            read -p "Digite o nome da branch para voltar: " existing_branch
            if git checkout "$existing_branch" > /dev/null 2>&1; then
                log_success "Voltou para branch '$existing_branch'"
            else
                log_error "Não foi possível voltar para branch '$existing_branch'"
                return 1
            fi
            ;;
        *)
            log_error "Opção inválida"
            return 1
            ;;
    esac
}

# Configurar upstream
setup_upstream() {
    local current_branch=$(git branch --show-current)
    log_info "Configurando upstream para branch '$current_branch'..."
    
    # Verificar se há remote configurado
    if ! git remote > /dev/null 2>&1; then
        log_warning "Nenhum remote configurado"
        read -p "Digite a URL do repositório remoto: " remote_url
        if [[ -n "$remote_url" ]]; then
            git remote add origin "$remote_url"
            log_success "Remote 'origin' adicionado"
        else
            log_error "URL do remote é obrigatória"
            return 1
        fi
    fi
    
    # Fazer push com upstream
    echo "Fazendo push e configurando upstream..."
    if git push -u origin "$current_branch" 2>/dev/null; then
        log_success "Upstream configurado para '$current_branch'"
    else
        log_warning "Falha no push. Tentando forçar criação da branch remota..."
        if git push -u origin "$current_branch" --force-with-lease 2>/dev/null; then
            log_success "Upstream configurado com force-with-lease"
        else
            log_error "Falha ao configurar upstream"
            echo "Verifique suas credenciais e conectividade"
            return 1
        fi
    fi
}

# Configurar Git para evitar problemas futuros
configure_git_defaults() {
    log_info "Configurando Git para evitar problemas futuros..."
    
    # Configurar push automático
    git config --global push.autoSetupRemote true
    git config --global push.default current
    
    # Configurar branch padrão
    git config --global init.defaultBranch main
    
    log_success "Configurações aplicadas:"
    echo "   - Push automático de upstream habilitado"
    echo "   - Branch padrão: main"
}

# Testar LazyGit
test_lazygit() {
    log_info "Testando LazyGit..."
    
    if command -v lazygit > /dev/null 2>&1; then
        echo "LazyGit encontrado. Você pode executar 'lazygit' agora."
        read -p "Deseja abrir o LazyGit agora? (s/n): " open_lazygit
        if [[ "$open_lazygit" =~ ^[Ss]$ ]]; then
            lazygit
        fi
    else
        log_warning "LazyGit não está instalado"
        echo "Para instalar: curl -Lo lazygit.tar.gz \"https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_\$(curl -s \"https://api.github.com/repos/jesseduffield/lazygit/releases/latest\" | grep -Po '\"tag_name\": \"v\\K[0-9.]+')_Linux_x86_64.tar.gz\" && tar xf lazygit.tar.gz lazygit && sudo install lazygit -D -t /usr/local/bin/ && rm lazygit.tar.gz lazygit"
    fi
}

# Função principal de correção
fix_upstream_issues() {
    local status_code
    check_repo_status
    status_code=$?
    
    case $status_code in
        0)
            log_success "Repositório já está configurado corretamente!"
            return 0
            ;;
        1)
            log_warning "Repositório sem commits"
            create_initial_commit
            setup_upstream
            ;;
        2)
            log_warning "HEAD desanexado detectado"
            fix_detached_head
            setup_upstream
            ;;
        3)
            log_warning "Branch sem upstream"
            setup_upstream
            ;;
    esac
}

# Menu principal
show_menu() {
    echo
    echo "Escolha uma opção:"
    echo "1) Correção automática completa (recomendado)"
    echo "2) Apenas verificar status"
    echo "3) Criar commit inicial"
    echo "4) Resolver HEAD desanexado"
    echo "5) Configurar upstream"
    echo "6) Configurar Git defaults"
    echo "7) Testar LazyGit"
    echo "8) Sair"
    echo
}

# Verificação inicial
check_git_repo

echo "Repositório: $(basename $(pwd))"
echo "Diretório: $(pwd)"
echo

# Loop principal
while true; do
    show_menu
    read -p "Digite sua opção (1-8) [1]: " option
    option=${option:-1}
    echo
    
    case $option in
        1)
            fix_upstream_issues
            configure_git_defaults
            test_lazygit
            echo
            log_success "Correção completa finalizada!"
            break
            ;;
        2)
            check_repo_status
            ;;
        3)
            create_initial_commit
            ;;
        4)
            fix_detached_head
            ;;
        5)
            setup_upstream
            ;;
        6)
            configure_git_defaults
            ;;
        7)
            test_lazygit
            ;;
        8)
            echo "👋 Script finalizado!"
            exit 0
            ;;
        *)
            log_error "Opção inválida!"
            ;;
    esac
done
