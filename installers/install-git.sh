#!/bin/bash

# Script para instalar Git e configurar com Personal Access Token
# Autor: Script automatizado para instalação e configuração Git

echo "=== Instalação e Configuração Automatizada do Git com Personal Access Token ==="
echo

# Função para validar entrada
validate_input() {
    if [[ -z "$1" ]]; then
        echo "❌ Erro: Campo obrigatório não pode estar vazio!"
        return 1
    fi
    return 0
}

# Função para instalar Git
install_git() {
    echo "🔧 Verificando instalação do Git..."
    
    if command -v git >/dev/null 2>&1; then
        echo "✅ Git já está instalado: $(git --version)"
        return 0
    fi
    
    echo "📦 Git não encontrado. Instalando..."
    
    # Detectar sistema operacional
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        echo "❌ Não foi possível detectar o sistema operacional"
        return 1
    fi
    
    case $OS in
        ubuntu|debian)
            echo "🐧 Detectado: $OS $VERSION"
            echo "Atualizando repositórios..."
            sudo apt update -y
            
            echo "Instalando Git..."
            sudo apt install git -y
            
            # Instalar dependências úteis
            sudo apt install curl wget -y
            ;;
        fedora)
            echo "🎩 Detectado: Fedora $VERSION"
            if [[ ${VERSION%%.*} -ge 22 ]]; then
                sudo dnf install git curl wget -y
            else
                sudo yum install git curl wget -y
            fi
            ;;
        centos|rhel)
            echo "🏢 Detectado: $OS $VERSION"
            sudo yum install git curl wget -y
            ;;
        arch)
            echo "🏹 Detectado: Arch Linux"
            sudo pacman -S git curl wget --noconfirm
            ;;
        *)
            echo "❌ Sistema operacional não suportado: $OS"
            echo "💡 Tente instalar o Git manualmente"
            return 1
            ;;
    esac
    
    # Verificar se a instalação foi bem-sucedida
    if command -v git >/dev/null 2>&1; then
        echo "✅ Git instalado com sucesso: $(git --version)"
        return 0
    else
        echo "❌ Falha na instalação do Git"
        return 1
    fi
}

# Função para configurar credenciais básicas
configure_git_user() {
    echo "📝 Configurando identidade do usuário Git..."
    
    # Pré-configurar com dados do usuário
    default_name="Erivelton de Lima da Cruz"
    default_email="erivelton@ufpel.edu.br"
    default_username="eriveltonlima"
    
    echo "Dados pré-configurados:"
    echo "Nome: $default_name"
    echo "Email: $default_email"
    echo "Username GitHub: $default_username"
    echo
    
    read -p "Deseja usar esses dados? (s/n): " use_defaults
    
    if [[ "$use_defaults" =~ ^[Ss]$ ]]; then
        git_name="$default_name"
        git_email="$default_email"
        github_username="$default_username"
    else
        read -p "Digite seu nome completo: " git_name
        validate_input "$git_name" || exit 1
        
        read -p "Digite seu email: " git_email
        validate_input "$git_email" || exit 1
        
        read -p "Digite seu username do GitHub: " github_username
        validate_input "$github_username" || exit 1
    fi
    
    # Configurar globalmente
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    echo "✅ Identidade configurada:"
    echo "   Nome: $git_name"
    echo "   Email: $git_email"
    echo "   Username GitHub: $github_username"
    echo
    
    # Retornar username para uso posterior
    export GITHUB_USERNAME="$github_username"
}

# Função para configurar cache de credenciais
configure_credential_cache() {
    echo "🔐 Configurando cache de credenciais..."
    
    echo "Escolha o método de armazenamento:"
    echo "1) Cache temporário (15 minutos)"
    echo "2) Cache longo (1 hora)"
    echo "3) Store permanente (arquivo) - Recomendado"
    echo "4) Pular configuração de cache"
    
    read -p "Escolha uma opção (1-4) [3]: " cache_option
    cache_option=${cache_option:-3}  # Default para opção 3
    
    case $cache_option in
        1)
            git config --global credential.helper cache
            echo "✅ Cache temporário configurado (15 minutos)"
            ;;
        2)
            git config --global credential.helper "cache --timeout=3600"
            echo "✅ Cache longo configurado (1 hora)"
            ;;
        3)
            git config --global credential.helper store
            echo "✅ Store permanente configurado"
            echo "💡 Credenciais serão salvas em ~/.git-credentials"
            ;;
        4)
            echo "⏭️  Cache de credenciais pulado"
            ;;
        *)
            echo "❌ Opção inválida, usando store permanente"
            git config --global credential.helper store
            ;;
    esac
    echo
}

# Função para configurar token
configure_github_token() {
    echo "🔗 Configurando Personal Access Token para GitHub..."
    
    if [[ -z "$GITHUB_USERNAME" ]]; then
        read -p "Digite seu username do GitHub: " GITHUB_USERNAME
        validate_input "$GITHUB_USERNAME" || return 1
    fi
    
    echo "Username GitHub: $GITHUB_USERNAME"
    
    read -s -p "Digite seu Personal Access Token: " token
    echo
    validate_input "$token" || return 1
    
    # Configurar credencial para GitHub
    git config --global credential."https://github.com".username "$GITHUB_USERNAME"
    
    # Se store estiver habilitado, salvar token
    if git config --global credential.helper | grep -q "store"; then
        echo "https://$GITHUB_USERNAME:$token@github.com" >> ~/.git-credentials
        echo "✅ Token configurado e salvo para GitHub"
    else
        echo "✅ Username configurado para GitHub"
        echo "💡 Token será solicitado na primeira operação Git"
    fi
    
    # Configurações adicionais úteis
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    
    echo "✅ Configurações adicionais aplicadas:"
    echo "   - Branch padrão: main"
    echo "   - Pull strategy: merge"
    echo "   - Line endings: input"
    echo
}

# Função para testar configuração
test_git_config() {
    echo "🧪 Testando configuração..."
    
    echo "Configurações atuais:"
    echo "Nome: $(git config --global user.name)"
    echo "Email: $(git config --global user.email)"
    echo "Credential Helper: $(git config --global credential.helper)"
    echo "Branch padrão: $(git config --global init.defaultBranch)"
    
    # Teste de conectividade com GitHub
    echo
    echo "Testando conectividade com GitHub..."
    if curl -s https://github.com >/dev/null; then
        echo "✅ Conectividade com GitHub OK"
    else
        echo "❌ Problema de conectividade com GitHub"
    fi
    
    # Verificar se há repositório local para testar
    if [[ -d .git ]]; then
        echo
        read -p "Deseja testar com o repositório atual? (s/n): " test_repo
        if [[ "$test_repo" =~ ^[Ss]$ ]]; then
            echo "Executando git remote -v..."
            git remote -v
            echo
            echo "💡 Para testar completamente, execute: git pull ou git push"
        fi
    fi
    echo
}

# Função para mostrar instruções do token
show_token_instructions() {
    echo "📋 Como criar um Personal Access Token no GitHub:"
    echo
    echo "1. Acesse: https://github.com/settings/tokens"
    echo "2. Clique em 'Generate new token' → 'Generate new token (classic)'"
    echo "3. Preencha:"
    echo "   - Note: 'Scripts repositório' ou nome descritivo"
    echo "   - Expiration: Escolha a duração (recomendo 1 year)"
    echo "   - Scopes: Marque 'repo' para acesso completo aos repositórios"
    echo "4. Clique em 'Generate token'"
    echo "5. IMPORTANTE: Copie o token imediatamente (só aparece uma vez)"
    echo "6. O token começa com 'ghp_'"
    echo
    read -p "Pressione ENTER após criar o token..."
    echo
}

# Função para configuração rápida
quick_setup() {
    echo "🚀 Configuração rápida para eriveltonlima..."
    
    install_git || exit 1
    configure_git_user
    configure_credential_cache
    show_token_instructions
    configure_github_token
    test_git_config
    
    echo "🎉 Configuração completa!"
    echo "💡 Agora você pode clonar repositórios e fazer push/pull normalmente"
}

# Função para limpar configurações
reset_git_config() {
    echo "🗑️  Limpando configurações Git..."
    
    read -p "Tem certeza que deseja limpar as configurações? (s/n): " confirm
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        git config --global --unset user.name 2>/dev/null
        git config --global --unset user.email 2>/dev/null
        git config --global --unset credential.helper 2>/dev/null
        git config --global --unset init.defaultBranch 2>/dev/null
        git config --global --unset pull.rebase 2>/dev/null
        git config --global --unset core.autocrlf 2>/dev/null
        
        # Limpar arquivo de credenciais se existir
        if [[ -f ~/.git-credentials ]]; then
            read -p "Deseja limpar o arquivo de credenciais também? (s/n): " clean_creds
            if [[ "$clean_creds" =~ ^[Ss]$ ]]; then
                rm ~/.git-credentials
                echo "✅ Arquivo de credenciais removido"
            fi
        fi
        
        echo "✅ Configurações Git limpas"
    else
        echo "❌ Operação cancelada"
    fi
    echo
}

# Menu principal
show_menu() {
    echo "Escolha uma opção:"
    echo "1) Configuração rápida completa (recomendado para eriveltonlima)"
    echo "2) Instalar apenas o Git"
    echo "3) Configurar apenas identidade (nome/email)"
    echo "4) Configurar apenas cache de credenciais"
    echo "5) Configurar token para GitHub"
    echo "6) Mostrar instruções para criar token"
    echo "7) Testar configuração atual"
    echo "8) Limpar configurações"
    echo "9) Sair"
    echo
}

# Verificar se está executando como root
if [[ $EUID -eq 0 ]]; then
    echo "⚠️  Executando como root. Algumas configurações serão aplicadas globalmente."
    echo
fi

# Loop principal
while true; do
    show_menu
    read -p "Digite sua opção (1-9) [1]: " option
    option=${option:-1}  # Default para opção 1
    echo
    
    case $option in
        1)
            quick_setup
            break
            ;;
        2)
            install_git
            ;;
        3)
            configure_git_user
            ;;
        4)
            configure_credential_cache
            ;;
        5)
            configure_github_token
            ;;
        6)
            show_token_instructions
            ;;
        7)
            test_git_config
            ;;
        8)
            reset_git_config
            ;;
        9)
            echo "👋 Script finalizado!"
            exit 0
            ;;
        *)
            echo "❌ Opção inválida!"
            echo
            ;;
    esac
done
