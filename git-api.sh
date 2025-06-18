#!/bin/bash

# Script para Configurar Token GitHub no Git
# Método: Git Credential Store

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Função para mostrar header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}                    🔐 CONFIGURADOR DE TOKEN GITHUB                    ${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}                     Método: Git Credential Store                     ${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Função para verificar se git está instalado
check_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git não está instalado!${NC}"
        echo -e "${YELLOW}💡 Instale o Git primeiro:${NC}"
        echo -e "   ${BLUE}sudo apt install git${NC} (Ubuntu/Debian)"
        echo -e "   ${BLUE}sudo yum install git${NC} (CentOS/RHEL)"
        exit 1
    fi
    echo -e "${GREEN}✅ Git encontrado: $(git --version)${NC}"
}

# Função para mostrar informações sobre o método
show_method_info() {
    echo -e "${BLUE}📋 Sobre este método:${NC}"
    echo -e "${WHITE}• Configura o Git para armazenar credenciais automaticamente${NC}"
    echo -e "${WHITE}• Salva username e token em ~/.git-credentials${NC}"
    echo -e "${WHITE}• Funciona para todos os repositórios${NC}"
    echo -e "${WHITE}• Não precisa digitar credenciais novamente${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Aviso de Segurança:${NC}"
    echo -e "${RED}• O token será salvo em texto plano${NC}"
    echo -e "${RED}• Qualquer pessoa com acesso ao seu usuário pode ver o token${NC}"
    echo -e "${RED}• Use apenas em máquinas pessoais/seguras${NC}"
    echo ""
}

# Função para verificar se já existe configuração
check_existing_config() {
    local helper=$(git config --global credential.helper 2>/dev/null)
    if [[ -n "$helper" ]]; then
        echo -e "${YELLOW}⚠️  Configuração existente encontrada:${NC}"
        echo -e "   ${BLUE}credential.helper = $helper${NC}"
        echo ""
        read -p "$(echo -e ${YELLOW}🔄${NC}) Deseja sobrescrever? [s/N]: " overwrite
        if [[ ! "$overwrite" =~ ^[Ss]$ ]]; then
            echo -e "${BLUE}❌ Operação cancelada${NC}"
            exit 0
        fi
    fi
}

# Função para configurar credential helper
configure_credential_helper() {
    echo -e "${BLUE}🔧 Configurando credential helper...${NC}"
    
    if git config --global credential.helper store; then
        echo -e "${GREEN}✅ Credential helper configurado com sucesso${NC}"
    else
        echo -e "${RED}❌ Erro ao configurar credential helper${NC}"
        exit 1
    fi
    
    echo ""
}

# Função para coletar informações do usuário
collect_user_info() {
    echo -e "${CYAN}📝 Configuração de Credenciais${NC}"
    echo ""
    
    # Username GitHub
    read -p "$(echo -e ${GREEN}👤${NC}) Username GitHub: " github_username
    if [[ -z "$github_username" ]]; then
        echo -e "${RED}❌ Username é obrigatório!${NC}"
        exit 1
    fi
    
    # Token GitHub
    echo -e "${GREEN}🔑 Token GitHub:${NC}"
    echo -e "${GRAY}   (O token não será exibido enquanto digita)${NC}"
    read -s github_token
    echo ""
    
    if [[ -z "$github_token" ]]; then
        echo -e "${RED}❌ Token é obrigatório!${NC}"
        exit 1
    fi
    
    # Confirmar informações
    echo ""
    echo -e "${BLUE}📋 Confirme as informações:${NC}"
    echo -e "${WHITE}• Username: $github_username${NC}"
    echo -e "${WHITE}• Token: ${github_token:0:4}...${github_token: -4}${NC}"
    echo ""
    
    read -p "$(echo -e ${GREEN}✅${NC}) Confirmar configuração? [S/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo -e "${BLUE}❌ Configuração cancelada${NC}"
        exit 0
    fi
}

# Função para testar configuração
test_configuration() {
    echo -e "${BLUE}🧪 Testando configuração...${NC}"
    echo ""
    
    # Criar arquivo de credenciais manualmente para teste
    local cred_file="$HOME/.git-credentials"
    echo "https://$github_username:$github_token@github.com" > "$cred_file"
    chmod 600 "$cred_file"
    
    echo -e "${GREEN}✅ Arquivo de credenciais criado: $cred_file${NC}"
    echo -e "${BLUE}🔒 Permissões definidas para 600 (apenas você pode ler)${NC}"
    echo ""
    
    # Verificar se o arquivo foi criado
    if [[ -f "$cred_file" ]]; then
        echo -e "${GREEN}✅ Configuração concluída com sucesso!${NC}"
        return 0
    else
        echo -e "${RED}❌ Erro ao criar arquivo de credenciais${NC}"
        return 1
    fi
}

# Função para mostrar instruções de uso
show_usage_instructions() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}                           🎉 CONFIGURAÇÃO CONCLUÍDA!                           ${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ Agora você pode usar o Git sem digitar credenciais!${NC}"
    echo ""
    echo -e "${BLUE}📋 Comandos que funcionarão automaticamente:${NC}"
    echo -e "${WHITE}• git clone https://github.com/usuario/repo.git${NC}"
    echo -e "${WHITE}• git push origin main${NC}"
    echo -e "${WHITE}• git pull origin main${NC}"
    echo -e "${WHITE}• git fetch${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Para usar no lazygit:${NC}"
    echo -e "${WHITE}• Abra o lazygit no seu repositório${NC}"
    echo -e "${WHITE}• Pressione Shift+P para push${NC}"
    echo -e "${WHITE}• Não será mais solicitado username/token${NC}"
    echo ""
    echo -e "${BLUE}📁 Arquivos criados/modificados:${NC}"
    echo -e "${WHITE}• ~/.gitconfig (credential.helper = store)${NC}"
    echo -e "${WHITE}• ~/.git-credentials (suas credenciais)${NC}"
    echo ""
}

# Função para mostrar opções de gerenciamento
show_management_options() {
    echo -e "${CYAN}🛠️  Opções de Gerenciamento:${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} 👁️  Ver configuração atual"
    echo -e "${GREEN}[2]${NC} 🗑️  Remover configuração"
    echo -e "${GREEN}[3]${NC} 🔄 Atualizar token"
    echo -e "${GREEN}[4]${NC} ❌ Sair"
    echo ""
    
    read -p "$(echo -e ${GREEN}🎯${NC}) Opção: " option
    
    case $option in
        1)
            show_current_config
            ;;
        2)
            remove_configuration
            ;;
        3)
            update_token
            ;;
        4)
            echo -e "${GREEN}👋 Até logo!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção inválida!${NC}"
            show_management_options
            ;;
    esac
}

# Função para mostrar configuração atual
show_current_config() {
    echo ""
    echo -e "${BLUE}📋 Configuração Atual:${NC}"
    echo ""
    
    local helper=$(git config --global credential.helper 2>/dev/null)
    if [[ -n "$helper" ]]; then
        echo -e "${GREEN}✅ Credential Helper: $helper${NC}"
    else
        echo -e "${RED}❌ Nenhum credential helper configurado${NC}"
    fi
    
    if [[ -f "$HOME/.git-credentials" ]]; then
        echo -e "${GREEN}✅ Arquivo de credenciais existe${NC}"
        echo -e "${BLUE}📁 Localização: $HOME/.git-credentials${NC}"
        echo -e "${BLUE}🔒 Permissões: $(ls -l $HOME/.git-credentials | cut -d' ' -f1)${NC}"
    else
        echo -e "${RED}❌ Arquivo de credenciais não encontrado${NC}"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
    show_management_options
}

# Função para remover configuração
remove_configuration() {
    echo ""
    echo -e "${RED}⚠️  Remover Configuração de Credenciais${NC}"
    echo -e "${YELLOW}Isso irá:${NC}"
    echo -e "${WHITE}• Remover o credential helper do Git${NC}"
    echo -e "${WHITE}• Deletar o arquivo ~/.git-credentials${NC}"
    echo -e "${WHITE}• Você precisará digitar credenciais novamente${NC}"
    echo ""
    
    read -p "$(echo -e ${RED}🗑️${NC}) Confirma a remoção? [s/N]: " confirm
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        git config --global --unset credential.helper 2>/dev/null
        rm -f "$HOME/.git-credentials"
        echo -e "${GREEN}✅ Configuração removida com sucesso!${NC}"
    else
        echo -e "${BLUE}❌ Remoção cancelada${NC}"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
    show_management_options
}

# Função para atualizar token
update_token() {
    echo ""
    echo -e "${BLUE}🔄 Atualizar Token GitHub${NC}"
    echo ""
    
    read -p "$(echo -e ${GREEN}👤${NC}) Username GitHub: " new_username
    echo -e "${GREEN}🔑 Novo Token GitHub:${NC}"
    read -s new_token
    echo ""
    
    if [[ -n "$new_username" && -n "$new_token" ]]; then
        echo "https://$new_username:$new_token@github.com" > "$HOME/.git-credentials"
        chmod 600 "$HOME/.git-credentials"
        echo -e "${GREEN}✅ Token atualizado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Username e token são obrigatórios!${NC}"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
    show_management_options
}

# Função principal
main() {
    show_header
    check_git
    echo ""
    show_method_info
    
    read -p "$(echo -e ${GREEN}🚀${NC}) Deseja continuar com a configuração? [S/n]: " continue_setup
    if [[ "$continue_setup" =~ ^[Nn]$ ]]; then
        echo -e "${BLUE}❌ Configuração cancelada${NC}"
        exit 0
    fi
    
    check_existing_config
    configure_credential_helper
    collect_user_info
    
    if test_configuration; then
        show_usage_instructions
        show_management_options
    else
        echo -e "${RED}❌ Falha na configuração!${NC}"
        exit 1
    fi
}

# Executar script
main
