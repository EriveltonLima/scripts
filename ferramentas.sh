#!/bin/bash

# Script Integrado de Ferramentas de Diagnóstico e Utilitários - VERSÃO MELHORADA
# Autor: Script para diagnóstico de sistema e rede com instalação automática
# Melhorado por: Erivelton de Lima da Cruz

clear
echo "=============================================="
echo "  FERRAMENTAS INTEGRADAS - DIAGNÓSTICO E UTILITÁRIOS"
echo "  VERSÃO MELHORADA COM INSTALAÇÃO AUTOMÁTICA"
echo "=============================================="

# Função para verificar se está rodando como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️  Este script precisa ser executado como root para instalar pacotes."
        echo "Execute: sudo $0"
        exit 1
    fi
}

# Função para instalar sudo se não existir
install_sudo() {
    if ! command -v sudo &> /dev/null; then
        echo "🔧 Instalando sudo..."
        apt update
        apt install -y sudo
        echo "✅ sudo instalado com sucesso!"
    fi
}

# Função para verificar e instalar uma ferramenta
check_and_install() {
    local tool="$1"
    local install_cmd="$2"
    local description="$3"
    
    if ! command -v "$tool" &> /dev/null; then
        echo "⚠️  $tool não encontrado. Instalando..."
        echo "📦 Instalando: $description"
        eval $install_cmd
        if [ $? -eq 0 ]; then
            echo "✅ $tool instalado com sucesso!"
        else
            echo "❌ Erro ao instalar $tool"
            return 1
        fi
    fi
    return 0
}

# Função para instalar lazydocker
install_lazydocker() {
    if ! command -v lazydocker &> /dev/null; then
        echo "🐳 Instalando LazyDocker..."
        
        # Detectar arquitetura
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            ARCH_SUFFIX="x86_64"
        else
            ARCH_SUFFIX="x86"
        fi
        
        # Baixar e instalar
        cd /tmp
        wget -q "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_*_Linux_${ARCH_SUFFIX}.tar.gz" -O lazydocker.tar.gz
        tar -xzf lazydocker.tar.gz
        sudo mv lazydocker /usr/local/bin/
        sudo chmod +x /usr/local/bin/lazydocker
        rm -f lazydocker.tar.gz
        
        echo "✅ LazyDocker instalado com sucesso!"
    fi
}

# Função para instalar lazygit
install_lazygit() {
    if ! command -v lazygit &> /dev/null; then
        echo "🔀 Instalando LazyGit..."
        
        # Obter última versão
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        
        # Baixar e instalar
        cd /tmp
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm -f lazygit.tar.gz lazygit
        
        echo "✅ LazyGit instalado com sucesso!"
    fi
}

# Função para instalar pathmanager.sh
install_pathmanager() {
    if [ ! -f "/usr/local/bin/pathmanager" ]; then
        echo "📁 Instalando PathManager..."
        
        # Baixar do repositório
        wget -q "https://raw.githubusercontent.com/EriveltonLima/scripts/main/pathmanager.sh" -O /tmp/pathmanager.sh
        
        if [ -f "/tmp/pathmanager.sh" ]; then
            sudo mv /tmp/pathmanager.sh /usr/local/bin/pathmanager
            sudo chmod +x /usr/local/bin/pathmanager
            echo "✅ PathManager instalado com sucesso!"
        else
            echo "❌ Erro ao baixar PathManager"
        fi
    fi
}

# Função de inicialização - instalar dependências
initialize_system() {
    echo "🚀 Inicializando sistema e instalando dependências..."
    
    # Verificar se é root
    check_root
    
    # Instalar sudo
    install_sudo
    
    # Atualizar repositórios
    echo "🔄 Atualizando repositórios..."
    apt update
    
    # Instalar ferramentas básicas
    check_and_install "curl" "apt install -y curl" "Cliente HTTP curl"
    check_and_install "wget" "apt install -y wget" "Downloader wget"
    check_and_install "git" "apt install -y git" "Sistema de controle de versão Git"
    
    # Instalar ferramentas de monitoramento
    check_and_install "btop" "apt install -y btop" "Monitor de sistema btop"
    check_and_install "nmap" "apt install -y nmap" "Scanner de rede nmap"
    check_and_install "speedtest-cli" "apt install -y speedtest-cli" "Teste de velocidade"
    check_and_install "mc" "apt install -y mc" "Midnight Commander"
    check_and_install "tree" "apt install -y tree" "Visualizador de árvore de diretórios"
    check_and_install "sensors" "apt install -y lm-sensors" "Sensores de hardware"
    check_and_install "upower" "apt install -y upower" "Gerenciador de energia"
    
    # Instalar Node.js para speed-cloudflare-cli
    if ! command -v node &> /dev/null; then
        echo "📦 Instalando Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt install -y nodejs
    fi
    
    # Instalar ferramentas especiais
    install_lazydocker
    install_lazygit
    install_pathmanager
    
    echo "✅ Sistema inicializado com todas as dependências!"
    echo ""
}

# Função para mostrar o menu principal
show_menu() {
    clear
    echo "=============================================="
    echo "  FERRAMENTAS INTEGRADAS - DIAGNÓSTICO E UTILITÁRIOS"
    echo "  VERSÃO MELHORADA COM INSTALAÇÃO AUTOMÁTICA"
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
    echo "9)  📊 btop (monitor de sistema avançado)"
    echo ""
    echo "=== DESENVOLVIMENTO E GIT ==="
    echo "10) 🐳 lazydocker (interface Docker)"
    echo "11) 🔀 lazygit (interface Git)"
    echo "12) 📁 pathmanager (gerenciador de PATH)"
    echo ""
    echo "=== NAVEGAÇÃO E ARQUIVOS ==="
    echo "13) 🌳 tree (árvore de arquivos)"
    echo "14) 📍 pwd (diretório atual)"
    echo "15) 📁 mc (Midnight Commander)"
    echo ""
    echo "=== GERENCIAMENTO ==="
    echo "16) ➕ Adicionar nova ferramenta"
    echo "17) 📋 Listar ferramentas adicionais"
    echo "18) 🗑️  Remover ferramenta adicional"
    echo "19) 🔄 Reinstalar dependências"
    echo ""
    
    # Carregar e mostrar ferramentas adicionais
    load_additional_tools
    if [ ${#tools[@]} -gt 0 ]; then
        echo "=== FERRAMENTAS ADICIONAIS ==="
        for i in "${!tools[@]}"; do
            local tool_entry=${tools[$i]}
            local cmd=$(echo "$tool_entry" | cut -d'|' -f1)
            local desc=$(echo "$tool_entry" | cut -d'|' -f2)
            echo "$((i + 20))) 🔧 $cmd ($desc)"
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
        read -p "Deseja tentar instalar automaticamente? (s/N): " install_confirm
        if [[ "$install_confirm" =~ ^[Ss]$ ]]; then
            read -p "Digite o comando de instalação (ex: apt install -y htop): " install_cmd
            echo "🔧 Tentando instalar $new_cmd..."
            eval "sudo $install_cmd"
            if [ $? -eq 0 ]; then
                echo "✅ $new_cmd instalado com sucesso!"
            else
                echo "❌ Erro ao instalar $new_cmd"
            fi
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

# Inicializar sistema na primeira execução
if [ "$1" = "--init" ] || [ ! -f ~/.tools_initialized ]; then
    initialize_system
    touch ~/.tools_initialized
    echo "Pressione ENTER para continuar para o menu principal..."
    read
fi

# Loop principal
while true; do
    show_menu
    
    case $option in
        1) 
            run_command "npx speed-cloudflare-cli" "Teste de velocidade via Cloudflare"
            ;;
        2)
            run_command "speedtest-cli" "Teste de velocidade via Ookla"
            ;;
        3)
            read -p "Digite o alvo para scan (ex: 192.168.1.0/24 ou 192.168.1.1): " target
            if [ -n "$target" ]; then
                run_command "nmap $target" "Scanner de rede - $target"
            else
                echo "Alvo não especificado."
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
            run_command "upower -i \$(upower -e)" "Informações de energia"
            ;;
        8)
            run_command "sensors" "Sensores de hardware"
            ;;
        9)
            echo "Executando btop - Monitor de sistema avançado..."
            btop
            ;;
        10)
            echo "Executando LazyDocker..."
            lazydocker
            ;;
        11)
            echo "Executando LazyGit..."
            lazygit
            ;;
        12)
            echo "Executando PathManager..."
            echo "Uso: pathmanager add <script> | pathmanager list | pathmanager remove <script>"
            pathmanager
            read -p "Pressione ENTER para continuar..."
            ;;
        13)
            run_command "tree" "Árvore de arquivos"
            ;;
        14)
            run_command "pwd && ls -la" "Diretório atual e conteúdo"
            ;;
        15)
            echo "Executando Midnight Commander..."
            mc
            ;;
        16)
            add_tool
            ;;
        17)
            list_additional_tools
            ;;
        18)
            remove_tool
            ;;
        19)
            initialize_system
            ;;
        0)
            echo "Saindo do script..."
            exit 0
            ;;
        *)
            # Verificar se é uma ferramenta adicional
            load_additional_tools
            if [[ $option =~ ^[0-9]+$ ]] && [ "$option" -ge 20 ]; then
                idx=$((option - 20))
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
