#!/bin/bash

# Script Integrado de Ferramentas de Diagnóstico e Utilitários
# Autor: Script para diagnóstico de sistema e rede

clear
echo "=============================================="
echo "  FERRAMENTAS INTEGRADAS - DIAGNÓSTICO E UTILITÁRIOS"
echo "=============================================="

# Função para verificar se uma ferramenta está instalada
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "⚠️  Aviso: $1 não está instalado"
        return 1
    fi
    return 0
}

# Função para mostrar o menu principal
show_menu() {
    clear
    echo "=============================================="
    echo "  FERRAMENTAS INTEGRADAS - DIAGNÓSTICO E UTILITÁRIOS"
    echo "=============================================="
    echo ""
    echo "=== TESTES DE REDE ==="
    echo "1)  🌐 speed-cloudflare-cli (velocidade Cloudflare)"
    echo "2)  🚀 speedtest-cli (teste velocidade Ookla)"
    echo "3)  🔍 nmap (scanner de rede)"
    echo ""
    echo "=== SISTEMA E HARDWARE ==="
    echo "4)  💾 df -h (espaço em disco)"
    echo "5)  🔧 lsblk -f (discos instalados)"
    echo "6)  🔌 lsusb (dispositivos USB)"
    echo "7)  🔋 upower (informações de energia)"
    echo "8)  🌡️  sensors (sensores de hardware)"
    echo "9)  💻 cpu-x (informações da CPU)"
    echo ""
    echo "=== NAVEGAÇÃO E ARQUIVOS ==="
    echo "10) 🌳 exa -T (árvore de arquivos)"
    echo "11) 📍 pwd (diretório atual)"
    echo "12) 📁 mc (Midnight Commander)"
    echo ""
    echo "=== GERENCIAMENTO ==="
    echo "13) ➕ Adicionar nova ferramenta"
    echo "14) 📋 Listar ferramentas adicionais"
    echo "15) 🗑️  Remover ferramenta adicional"
    echo ""
    
    # Carregar e mostrar ferramentas adicionais
    load_additional_tools
    if [ ${#tools[@]} -gt 0 ]; then
        echo "=== FERRAMENTAS ADICIONAIS ==="
        for i in "${!tools[@]}"; do
            local tool_entry=${tools[$i]}
            local cmd=$(echo "$tool_entry" | cut -d'|' -f1)
            local desc=$(echo "$tool_entry" | cut -d'|' -f2)
            echo "$((i + 16))) 🔧 $cmd ($desc)"
        done
        echo ""
    fi
    
    echo "0) ❌ Sair"
    echo ""
    read -p "Digite a opção desejada: " option
}

# Função para adicionar nova ferramenta
add_tool() {
    echo "=== ADICIONAR NOVA FERRAMENTA ==="
    echo ""
    read -p "Digite o comando da nova ferramenta (ex: htop): " new_cmd
    
    # Verificar se o comando existe
    if ! command -v "$new_cmd" &> /dev/null; then
        echo "⚠️  Aviso: O comando '$new_cmd' não foi encontrado no sistema."
        read -p "Deseja adicionar mesmo assim? (s/N): " confirm
        if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
            echo "Operação cancelada."
            return
        fi
    fi
    
    read -p "Digite uma descrição para a ferramenta: " new_desc
    read -p "Precisa de parâmetros adicionais? (deixe vazio se não): " new_params
    
    # Adiciona a nova ferramenta ao arquivo
    if [ -n "$new_params" ]; then
        echo "$new_cmd $new_params|$new_desc" >> ~/.tools_list.txt
    else
        echo "$new_cmd|$new_desc" >> ~/.tools_list.txt
    fi
    
    echo "✅ Nova ferramenta '$new_cmd' adicionada com sucesso!"
    read -p "Pressione ENTER para continuar..."
}

# Função para carregar ferramentas adicionais
load_additional_tools() {
    if [ -f ~/.tools_list.txt ]; then
        mapfile -t tools < ~/.tools_list.txt
    else
        tools=()
    fi
}

# Função para listar ferramentas adicionais
list_additional_tools() {
    echo "=== FERRAMENTAS ADICIONAIS ==="
    load_additional_tools
    
    if [ ${#tools[@]} -eq 0 ]; then
        echo "Nenhuma ferramenta adicional cadastrada."
    else
        for i in "${!tools[@]}"; do
            local tool_entry=${tools[$i]}
            local cmd=$(echo "$tool_entry" | cut -d'|' -f1)
            local desc=$(echo "$tool_entry" | cut -d'|' -f2)
            echo "$((i + 1)). $cmd - $desc"
        done
    fi
    
    read -p "Pressione ENTER para continuar..."
}

# Função para remover ferramenta adicional
remove_tool() {
    echo "=== REMOVER FERRAMENTA ADICIONAL ==="
    load_additional_tools
    
    if [ ${#tools[@]} -eq 0 ]; then
        echo "Nenhuma ferramenta adicional para remover."
        read -p "Pressione ENTER para continuar..."
        return
    fi
    
    echo "Ferramentas disponíveis para remoção:"
    for i in "${!tools[@]}"; do
        local tool_entry=${tools[$i]}
        local cmd=$(echo "$tool_entry" | cut -d'|' -f1)
        local desc=$(echo "$tool_entry" | cut -d'|' -f2)
        echo "$((i + 1)). $cmd - $desc"
    done
    
    read -p "Digite o número da ferramenta a remover (0 para cancelar): " remove_idx
    
    if [[ "$remove_idx" =~ ^[0-9]+$ ]] && [ "$remove_idx" -gt 0 ] && [ "$remove_idx" -le ${#tools[@]} ]; then
        # Remover a linha específica do arquivo
        sed -i "${remove_idx}d" ~/.tools_list.txt
        echo "✅ Ferramenta removida com sucesso!"
    else
        echo "Operação cancelada."
    fi
    
    read -p "Pressione ENTER para continuar..."
}

# Função para executar ferramenta adicional
run_additional_tool() {
    local idx=$1
    local tool_entry=${tools[$idx]}
    local cmd=$(echo "$tool_entry" | cut -d'|' -f1)
    local desc=$(echo "$tool_entry" | cut -d'|' -f2)
    
    echo "Executando: $desc"
    echo "Comando: $cmd"
    echo "=============================================="
    
    # Executar o comando
    eval $cmd
    
    echo "=============================================="
    read -p "Pressione ENTER para continuar..."
}

# Função para executar comandos com verificação
run_command() {
    local cmd="$1"
    local desc="$2"
    
    echo "Executando: $desc"
    echo "=============================================="
    
    eval $cmd
    
    echo "=============================================="
    read -p "Pressione ENTER para continuar..."
}

# Loop principal
while true; do
    show_menu
    
    case $option in
        1) 
            if check_tool "npx"; then
                run_command "npx speed-cloudflare-cli" "Teste de velocidade via Cloudflare"
            else
                echo "Node.js/npm não encontrado. Instale com: sudo apt install nodejs npm"
                read -p "Pressione ENTER para continuar..."
            fi
            ;;
        2)
            if check_tool "speedtest-cli"; then
                run_command "speedtest-cli" "Teste de velocidade via Ookla"
            else
                echo "speedtest-cli não encontrado. Instale com: sudo apt install speedtest-cli"
                read -p "Pressione ENTER para continuar..."
            fi
            ;;
        3)
            if check_tool "nmap"; then
                read -p "Digite o alvo para scan (ex: 192.168.1.0/24 ou 192.168.1.1): " target
                if [ -n "$target" ]; then
                    run_command "nmap $target" "Scanner de rede - $target"
                else
                    echo "Alvo não especificado."
                    read -p "Pressione ENTER para continuar..."
                fi
            else
                echo "nmap não encontrado. Instale com: sudo apt install nmap"
                read -p "Pressione ENTER para continuar..."
            fi
            ;;
        4)
            run_command "df -h" "Espaço em disco"
            ;;
        5)
            run_command "lsblk -f" "Discos e sistemas de arquivos"
            ;;
        6)
            run_command "lsusb" "Dispositivos USB conectados"
            ;;
        7)
            if check_tool "upower"; then
                run_command "upower -i \$(upower -e)" "Informações de energia"
            else
                echo "upower não encontrado. Instale com: sudo apt install upower"
                read -p "Pressione ENTER para continuar..."
            fi
            ;;
        8)
            if check_tool "sensors"; then
                run_command "sensors" "Sensores de hardware"
            else
                echo "sensors não encontrado. Instale com: sudo apt install lm-sensors"
                read -p "Pressione ENTER para continuar..."
            fi
            ;;
        9)
            if check_tool "cpu-x"; then
                run_command "cpu-x" "Informações detalhadas da CPU"
            else
                echo "cpu-x não encontrado. Instale com: sudo apt install cpu-x"
                read -p "Pressione ENTER para continuar..."
            fi
            ;;
        10)
            if check_tool "exa"; then
                run_command "exa -T" "Árvore de arquivos (exa)"
            else
                echo "exa não encontrado. Usando tree como alternativa..."
                if check_tool "tree"; then
                    run_command "tree" "Árvore de arquivos (tree)"
                else
                    echo "Nem exa nem tree encontrados. Instale com: sudo apt install exa tree"
                    read -p "Pressione ENTER para continuar..."
                fi
            fi
            ;;
        11)
            run_command "pwd && ls -la" "Diretório atual e conteúdo"
            ;;
        12)
            if check_tool "mc"; then
                echo "Executando Midnight Commander..."
                mc
            else
                echo "mc não encontrado. Instale com: sudo apt install mc"
                read -p "Pressione ENTER para continuar..."
            fi
            ;;
        13)
            add_tool
            ;;
        14)
            list_additional_tools
            ;;
        15)
            remove_tool
            ;;
        0)
            echo "Saindo do script..."
            exit 0
            ;;
        *)
            # Verificar se é uma ferramenta adicional
            load_additional_tools
            if [[ $option =~ ^[0-9]+$ ]] && [ "$option" -ge 16 ]; then
                idx=$((option - 16))
                if [ $idx -ge 0 ] && [ $idx -lt ${#tools[@]} ]; then
                    run_additional_tool $idx
                else
                    echo "Opção inválida!"
                    read -p "Pressione ENTER para continuar..."
                fi
            else
                echo "Opção inválida!"
                read -p "Pressione ENTER para continuar..."
            fi
            ;;
    esac
done
