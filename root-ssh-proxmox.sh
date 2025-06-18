#!/bin/bash

# Script Interativo para Habilitar SSH Root em Container LXC
# Versão: 2.0
# Autor: Assistente IA

# Cores para interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Função para exibir cabeçalho
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}          CONFIGURADOR SSH ROOT PARA CONTAINERS LXC           ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}                    Versão Interativa 2.0                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Função para exibir menu principal
show_main_menu() {
    echo -e "${YELLOW}┌─ MENU PRINCIPAL ─────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} 1. Configurar SSH Root (Senha + Configuração)               ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} 2. Apenas Alterar Senha do Root                             ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} 3. Apenas Configurar SSH (sem alterar senha)                ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} 4. Verificar Status do Container                            ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} 5. Testar Conexão SSH                                       ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} 6. Restaurar Backup da Configuração SSH                     ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} 7. Listar Containers LXC                                    ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} 0. Sair                                                     ${YELLOW}│${NC}"
    echo -e "${YELLOW}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Função para listar containers
list_containers() {
    echo -e "${BLUE}📋 Containers LXC Disponíveis:${NC}"
    echo ""
    pct list | head -1
    echo "────────────────────────────────────────────────────────────────"
    pct list | tail -n +2 | while read line; do
        container_id=$(echo $line | awk '{print $1}')
        status=$(echo $line | awk '{print $2}')
        name=$(echo $line | awk '{print $3}')
        
        if [ "$status" = "running" ]; then
            echo -e "${GREEN}$line${NC}"
        else
            echo -e "${RED}$line${NC}"
        fi
    done
    echo ""
}

# Função para validar ID do container
validate_container() {
    local container_id=$1
    
    if [ -z "$container_id" ]; then
        echo -e "${RED}❌ ID do container não pode estar vazio!${NC}"
        return 1
    fi
    
    if ! [[ "$container_id" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}❌ ID do container deve ser numérico!${NC}"
        return 1
    fi
    
    if ! pct status $container_id >/dev/null 2>&1; then
        echo -e "${RED}❌ Container $container_id não encontrado!${NC}"
        return 1
    fi
    
    local status=$(pct status $container_id | awk '{print $2}')
    if [ "$status" != "running" ]; then
        echo -e "${YELLOW}⚠️  Container $container_id não está em execução!${NC}"
        echo -e "${YELLOW}Deseja iniciar o container? (s/N): ${NC}"
        read -r start_container
        if [[ $start_container =~ ^[Ss]$ ]]; then
            echo -e "${BLUE}🚀 Iniciando container $container_id...${NC}"
            pct start $container_id
            sleep 3
        else
            return 1
        fi
    fi
    
    return 0
}

# Função para obter ID do container
get_container_id() {
    while true; do
        echo -e "${CYAN}🔢 Digite o ID do container LXC: ${NC}"
        read -r container_id
        
        if validate_container "$container_id"; then
            echo "$container_id"
            return 0
        fi
        
        echo -e "${YELLOW}Pressione Enter para tentar novamente ou 'q' para voltar ao menu: ${NC}"
        read -r retry
        if [[ $retry =~ ^[Qq]$ ]]; then
            return 1
        fi
    done
}

# Função para obter senha segura
get_secure_password() {
    while true; do
        echo -e "${CYAN}🔐 Digite a nova senha para o usuário root: ${NC}"
        read -s password1
        echo ""
        
        if [ ${#password1} -lt 8 ]; then
            echo -e "${RED}❌ A senha deve ter pelo menos 8 caracteres!${NC}"
            continue
        fi
        
        echo -e "${CYAN}🔐 Confirme a senha: ${NC}"
        read -s password2
        echo ""
        
        if [ "$password1" != "$password2" ]; then
            echo -e "${RED}❌ As senhas não coincidem!${NC}"
            continue
        fi
        
        echo "$password1"
        return 0
    done
}

# Função para configurar SSH
configure_ssh() {
    local container_id=$1
    local change_password=$2
    local new_password=$3
    
    echo -e "${BLUE}🔧 Configurando SSH para container $container_id...${NC}"
    
    # Alterar senha se solicitado
    if [ "$change_password" = "yes" ] && [ ! -z "$new_password" ]; then
        echo -e "${YELLOW}📝 Alterando senha do root...${NC}"
        if pct exec $container_id -- bash -c "echo 'root:$new_password' | chpasswd"; then
            echo -e "${GREEN}✅ Senha alterada com sucesso!${NC}"
        else
            echo -e "${RED}❌ Erro ao alterar senha!${NC}"
            return 1
        fi
    fi
    
    # Configurar SSH
    echo -e "${YELLOW}🔧 Configurando arquivo SSH...${NC}"
    
    pct exec $container_id -- bash -c '
        # Criar backup se não existir
        if [ ! -f /etc/ssh/sshd_config.backup ]; then
            cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
            echo "Backup criado: /etc/ssh/sshd_config.backup"
        fi
        
        # Configurar PermitRootLogin
        sed -i "/^#*PermitRootLogin/c\PermitRootLogin yes" /etc/ssh/sshd_config
        if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
            echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
        fi
        
        # Configurar PasswordAuthentication
        sed -i "/^#*PasswordAuthentication/c\PasswordAuthentication yes" /etc/ssh/sshd_config
        if ! grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
            echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
        fi
        
        # Reiniciar SSH
        systemctl restart sshd || service ssh restart
        
        # Verificar status
        if systemctl is-active sshd >/dev/null 2>&1 || systemctl is-active ssh >/dev/null 2>&1; then
            echo "SSH configurado e reiniciado com sucesso!"
            exit 0
        else
            echo "Erro ao reiniciar SSH!"
            exit 1
        fi
    '
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSH configurado com sucesso!${NC}"
        
        # Obter IP do container
        local container_ip=$(pct exec $container_id -- hostname -I 2>/dev/null | awk '{print $1}')
        if [ ! -z "$container_ip" ]; then
            echo -e "${GREEN}🌐 IP do container: $container_ip${NC}"
            echo -e "${GREEN}🔗 Teste com: ssh root@$container_ip${NC}"
        fi
        return 0
    else
        echo -e "${RED}❌ Erro ao configurar SSH!${NC}"
        return 1
    fi
}

# Função para verificar status
check_status() {
    local container_id=$(get_container_id)
    if [ $? -ne 0 ]; then return; fi
    
    echo -e "${BLUE}📊 Status do Container $container_id:${NC}"
    echo ""
    
    # Status geral
    echo -e "${YELLOW}🔍 Status Geral:${NC}"
    pct status $container_id
    echo ""
    
    # Status SSH
    echo -e "${YELLOW}🔍 Status SSH:${NC}"
    pct exec $container_id -- systemctl status sshd 2>/dev/null || pct exec $container_id -- systemctl status ssh 2>/dev/null
    echo ""
    
    # Configuração SSH
    echo -e "${YELLOW}🔍 Configuração SSH Atual:${NC}"
    echo "PermitRootLogin: $(pct exec $container_id -- grep "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null || echo "Não configurado")"
    echo "PasswordAuthentication: $(pct exec $container_id -- grep "^PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null || echo "Não configurado")"
    echo ""
    
    # IP do container
    local container_ip=$(pct exec $container_id -- hostname -I 2>/dev/null | awk '{print $1}')
    if [ ! -z "$container_ip" ]; then
        echo -e "${GREEN}🌐 IP do Container: $container_ip${NC}"
    fi
}

# Função para testar SSH
test_ssh() {
    local container_id=$(get_container_id)
    if [ $? -ne 0 ]; then return; fi
    
    local container_ip=$(pct exec $container_id -- hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$container_ip" ]; then
        echo -e "${RED}❌ Não foi possível obter o IP do container!${NC}"
        return
    fi
    
    echo -e "${BLUE}🧪 Testando conexão SSH para $container_ip...${NC}"
    echo -e "${YELLOW}Pressione Ctrl+C para cancelar o teste${NC}"
    echo ""
    
    ssh -o ConnectTimeout=10 -o BatchMode=yes root@$container_ip exit 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Conexão SSH funcionando! (autenticação por chave)${NC}"
    else
        echo -e "${YELLOW}⚠️  Testando conexão SSH com senha...${NC}"
        echo -e "${CYAN}Digite a senha do root quando solicitado:${NC}"
        ssh -o ConnectTimeout=10 root@$container_ip exit
    fi
}

# Função para restaurar backup
restore_backup() {
    local container_id=$(get_container_id)
    if [ $? -ne 0 ]; then return; fi
    
    echo -e "${YELLOW}⚠️  Tem certeza que deseja restaurar o backup da configuração SSH? (s/N): ${NC}"
    read -r confirm
    
    if [[ $confirm =~ ^[Ss]$ ]]; then
        pct exec $container_id -- bash -c '
            if [ -f /etc/ssh/sshd_config.backup ]; then
                cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
                systemctl restart sshd || service ssh restart
                echo "Backup restaurado e SSH reiniciado!"
            else
                echo "Arquivo de backup não encontrado!"
                exit 1
            fi
        '
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Backup restaurado com sucesso!${NC}"
        else
            echo -e "${RED}❌ Erro ao restaurar backup!${NC}"
        fi
    fi
}

# Função para pausar e aguardar input
pause() {
    echo ""
    echo -e "${CYAN}Pressione Enter para continuar...${NC}"
    read -r
}

# Função principal
main() {
    while true; do
        show_header
        list_containers
        show_main_menu
        
        echo -e "${CYAN}Escolha uma opção: ${NC}"
        read -r option
        
        case $option in
            1)
                show_header
                echo -e "${PURPLE}🔧 CONFIGURAÇÃO COMPLETA SSH ROOT${NC}"
                echo ""
                
                container_id=$(get_container_id)
                if [ $? -ne 0 ]; then pause; continue; fi
                
                new_password=$(get_secure_password)
                
                configure_ssh "$container_id" "yes" "$new_password"
                pause
                ;;
            2)
                show_header
                echo -e "${PURPLE}🔐 ALTERAR SENHA DO ROOT${NC}"
                echo ""
                
                container_id=$(get_container_id)
                if [ $? -ne 0 ]; then pause; continue; fi
                
                new_password=$(get_secure_password)
                
                if pct exec $container_id -- bash -c "echo 'root:$new_password' | chpasswd"; then
                    echo -e "${GREEN}✅ Senha alterada com sucesso!${NC}"
                else
                    echo -e "${RED}❌ Erro ao alterar senha!${NC}"
                fi
                pause
                ;;
            3)
                show_header
                echo -e "${PURPLE}⚙️  CONFIGURAR APENAS SSH${NC}"
                echo ""
                
                container_id=$(get_container_id)
                if [ $? -ne 0 ]; then pause; continue; fi
                
                configure_ssh "$container_id" "no" ""
                pause
                ;;
            4)
                show_header
                check_status
                pause
                ;;
            5)
                show_header
                test_ssh
                pause
                ;;
            6)
                show_header
                restore_backup
                pause
                ;;
            7)
                show_header
                list_containers
                pause
                ;;
            0)
                echo -e "${GREEN}👋 Obrigado por usar o Configurador SSH LXC!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opção inválida! Tente novamente.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Este script deve ser executado como root!${NC}"
    echo "Use: sudo $0"
    exit 1
fi

# Verificar se o Proxmox está instalado
if ! command -v pct &> /dev/null; then
    echo -e "${RED}❌ Comando 'pct' não encontrado! Este script é para Proxmox VE.${NC}"
    exit 1
fi

# Iniciar script
main
