#!/bin/bash
# Script Interativo para Controlar Boot de Containers/VMs no Proxmox

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function mostrar_banner() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}    Controle de Boot - Proxmox VE${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

function listar_containers() {
    echo -e "${YELLOW}Containers LXC disponíveis:${NC}"
    pct list | awk 'NR>1 {printf "%s - %s (Status: %s)\n", $1, $3, $2}'
    echo
}

function listar_vms() {
    echo -e "${YELLOW}VMs disponíveis:${NC}"
    qm list | awk 'NR>1 {printf "%s - %s (Status: %s)\n", $1, $2, $3}'
    echo
}

function verificar_status_boot() {
    local tipo=$1
    local id=$2
    
    if [ "$tipo" == "container" ]; then
        status=$(pct config $id | grep "onboot:" | cut -d' ' -f2)
        startup=$(pct config $id | grep "startup:" | cut -d' ' -f2)
    else
        status=$(qm config $id | grep "onboot:" | cut -d' ' -f2)
        startup=$(qm config $id | grep "startup:" | cut -d' ' -f2)
    fi
    
    if [ "$status" == "1" ]; then
        echo -e "${GREEN}Autostart: HABILITADO${NC}"
        [ ! -z "$startup" ] && echo -e "${BLUE}Configuração: $startup${NC}"
    else
        echo -e "${RED}Autostart: DESABILITADO${NC}"
    fi
}

function configurar_individual() {
    local tipo=$1
    
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo "1) Habilitar autostart"
    echo "2) Desabilitar autostart"
    echo "3) Configurar com ordem e delay"
    echo "4) Verificar status atual"
    echo "0) Voltar"
    
    read -p "Opção: " opcao
    
    case $opcao in
        1|2|3|4)
            if [ "$tipo" == "container" ]; then
                listar_containers
                read -p "Digite o ID do container: " id
                if ! pct status $id &>/dev/null; then
                    echo -e "${RED}Container $id não encontrado!${NC}"
                    return
                fi
            else
                listar_vms
                read -p "Digite o ID da VM: " id
                if ! qm status $id &>/dev/null; then
                    echo -e "${RED}VM $id não encontrada!${NC}"
                    return
                fi
            fi
            
            case $opcao in
                1)
                    if [ "$tipo" == "container" ]; then
                        pct set $id --onboot 1
                    else
                        qm set $id --onboot 1
                    fi
                    echo -e "${GREEN}Autostart habilitado para $tipo $id${NC}"
                    ;;
                2)
                    if [ "$tipo" == "container" ]; then
                        pct set $id --onboot 0
                    else
                        qm set $id --onboot 0
                    fi
                    echo -e "${RED}Autostart desabilitado para $tipo $id${NC}"
                    ;;
                3)
                    read -p "Ordem de inicialização (1-999): " ordem
                    read -p "Delay de inicialização em segundos (padrão 30): " delay
                    delay=${delay:-30}
                    
                    if [ "$tipo" == "container" ]; then
                        pct set $id --onboot 1 --startup "order=$ordem,up=$delay"
                    else
                        qm set $id --onboot 1 --startup "order=$ordem,up=$delay"
                    fi
                    echo -e "${GREEN}$tipo $id configurado: ordem=$ordem, delay=${delay}s${NC}"
                    ;;
                4)
                    echo -e "${BLUE}Status do $tipo $id:${NC}"
                    verificar_status_boot $tipo $id
                    ;;
            esac
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

function configurar_todos() {
    local tipo=$1
    
    echo -e "${YELLOW}Escolha uma opção para TODOS os ${tipo}s:${NC}"
    echo "1) Habilitar autostart em todos"
    echo "2) Desabilitar autostart em todos"
    echo "3) Configurar todos com ordem sequencial e delay"
    echo "4) Mostrar status de todos"
    echo "0) Voltar"
    
    read -p "Opção: " opcao
    
    case $opcao in
        1)
            if [ "$tipo" == "container" ]; then
                for id in $(pct list | awk 'NR>1 {print $1}'); do
                    pct set $id --onboot 1
                    echo -e "${GREEN}Container $id: autostart habilitado${NC}"
                done
            else
                for id in $(qm list | awk 'NR>1 {print $1}'); do
                    qm set $id --onboot 1
                    echo -e "${GREEN}VM $id: autostart habilitado${NC}"
                done
            fi
            ;;
        2)
            if [ "$tipo" == "container" ]; then
                for id in $(pct list | awk 'NR>1 {print $1}'); do
                    pct set $id --onboot 0
                    echo -e "${RED}Container $id: autostart desabilitado${NC}"
                done
            else
                for id in $(qm list | awk 'NR>1 {print $1}'); do
                    qm set $id --onboot 0
                    echo -e "${RED}VM $id: autostart desabilitado${NC}"
                done
            fi
            ;;
        3)
            read -p "Delay entre inicializações em segundos (padrão 30): " delay
            delay=${delay:-30}
            
            ordem=1
            if [ "$tipo" == "container" ]; then
                for id in $(pct list | awk 'NR>1 {print $1}'); do
                    pct set $id --onboot 1 --startup "order=$ordem,up=$delay"
                    echo -e "${GREEN}Container $id: ordem=$ordem, delay=${delay}s${NC}"
                    ((ordem++))
                done
            else
                for id in $(qm list | awk 'NR>1 {print $1}'); do
                    qm set $id --onboot 1 --startup "order=$ordem,up=$delay"
                    echo -e "${GREEN}VM $id: ordem=$ordem, delay=${delay}s${NC}"
                    ((ordem++))
                done
            fi
            ;;
        4)
            if [ "$tipo" == "container" ]; then
                for id in $(pct list | awk 'NR>1 {print $1}'); do
                    echo -e "${BLUE}Container $id:${NC}"
                    verificar_status_boot container $id
                    echo
                done
            else
                for id in $(qm list | awk 'NR>1 {print $1}'); do
                    echo -e "${BLUE}VM $id:${NC}"
                    verificar_status_boot vm $id
                    echo
                done
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

function menu_principal() {
    while true; do
        clear
        mostrar_banner
        
        echo -e "${YELLOW}Menu Principal:${NC}"
        echo "1) Gerenciar Containers LXC"
        echo "2) Gerenciar VMs"
        echo "3) Configurar TODOS (Containers + VMs)"
        echo "4) Mostrar status geral"
        echo "0) Sair"
        echo
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1)
                menu_containers
                ;;
            2)
                menu_vms
                ;;
            3)
                menu_todos
                ;;
            4)
                mostrar_status_geral
                ;;
            0)
                echo -e "${GREEN}Saindo...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                read -p "Pressione Enter para continuar..."
                ;;
        esac
    done
}

function menu_containers() {
    while true; do
        clear
        mostrar_banner
        listar_containers
        
        echo -e "${YELLOW}Gerenciar Containers:${NC}"
        echo "1) Configurar container individual"
        echo "2) Configurar todos os containers"
        echo "0) Voltar"
        echo
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1)
                configurar_individual container
                ;;
            2)
                configurar_todos container
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                read -p "Pressione Enter para continuar..."
                ;;
        esac
    done
}

function menu_vms() {
    while true; do
        clear
        mostrar_banner
        listar_vms
        
        echo -e "${YELLOW}Gerenciar VMs:${NC}"
        echo "1) Configurar VM individual"
        echo "2) Configurar todas as VMs"
        echo "0) Voltar"
        echo
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1)
                configurar_individual vm
                ;;
            2)
                configurar_todos vm
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                read -p "Pressione Enter para continuar..."
                ;;
        esac
    done
}

function menu_todos() {
    echo -e "${YELLOW}Configurar TODOS (Containers + VMs):${NC}"
    echo "1) Habilitar autostart em TUDO"
    echo "2) Desabilitar autostart em TUDO"
    echo "3) Configurar ordem sequencial (Containers primeiro, depois VMs)"
    echo "0) Voltar"
    
    read -p "Opção: " opcao
    
    case $opcao in
        1)
            echo -e "${GREEN}Habilitando autostart em todos os containers...${NC}"
            for id in $(pct list | awk 'NR>1 {print $1}'); do
                pct set $id --onboot 1
                echo "Container $id: autostart habilitado"
            done
            
            echo -e "${GREEN}Habilitando autostart em todas as VMs...${NC}"
            for id in $(qm list | awk 'NR>1 {print $1}'); do
                qm set $id --onboot 1
                echo "VM $id: autostart habilitado"
            done
            ;;
        2)
            echo -e "${RED}Desabilitando autostart em todos os containers...${NC}"
            for id in $(pct list | awk 'NR>1 {print $1}'); do
                pct set $id --onboot 0
                echo "Container $id: autostart desabilitado"
            done
            
            echo -e "${RED}Desabilitando autostart em todas as VMs...${NC}"
            for id in $(qm list | awk 'NR>1 {print $1}'); do
                qm set $id --onboot 0
                echo "VM $id: autostart desabilitado"
            done
            ;;
        3)
            read -p "Delay entre inicializações em segundos (padrão 30): " delay
            delay=${delay:-30}
            
            ordem=1
            echo -e "${GREEN}Configurando containers primeiro...${NC}"
            for id in $(pct list | awk 'NR>1 {print $1}'); do
                pct set $id --onboot 1 --startup "order=$ordem,up=$delay"
                echo "Container $id: ordem=$ordem, delay=${delay}s"
                ((ordem++))
            done
            
            echo -e "${GREEN}Configurando VMs depois...${NC}"
            for id in $(qm list | awk 'NR>1 {print $1}'); do
                qm set $id --onboot 1 --startup "order=$ordem,up=$delay"
                echo "VM $id: ordem=$ordem, delay=${delay}s"
                ((ordem++))
            done
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

function mostrar_status_geral() {
    clear
    mostrar_banner
    
    echo -e "${YELLOW}Status Geral de Autostart:${NC}"
    echo
    
    echo -e "${BLUE}=== CONTAINERS LXC ===${NC}"
    for id in $(pct list | awk 'NR>1 {print $1}'); do
        nome=$(pct list | awk -v id="$id" '$1==id {print $3}')
        echo -e "${YELLOW}Container $id ($nome):${NC}"
        verificar_status_boot container $id
        echo
    done
    
    echo -e "${BLUE}=== VIRTUAL MACHINES ===${NC}"
    for id in $(qm list | awk 'NR>1 {print $1}'); do
        nome=$(qm list | awk -v id="$id" '$1==id {print $2}')
        echo -e "${YELLOW}VM $id ($nome):${NC}"
        verificar_status_boot vm $id
        echo
    done
    
    read -p "Pressione Enter para continuar..."
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Este script deve ser executado como root!${NC}"
    exit 1
fi

# Iniciar o menu principal
menu_principal
