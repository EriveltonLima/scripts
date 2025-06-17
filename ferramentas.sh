#!/bin/bash

# Script Integrado de Ferramentas de Diagnóstico e Utilitários - VERSÃO SEM SUDO
# Autor: Script para diagnóstico de sistema e rede
# Modificado por: Erivelton de Lima da Cruz

clear
echo "=============================================="
echo "  FERRAMENTAS INTEGRADAS - DIAGNÓSTICO E UTILITÁRIOS"
echo "  VERSÃO SEM SUDO - INSTALAÇÃO OPCIONAL"
echo "=============================================="

# Função para verificar se uma ferramenta está instalada
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Função para oferecer instalação de ferramenta
offer_install() {
    local tool="$1"
    local install_cmd="$2"
    local description="$3"
    
    echo ""
    echo "⚠️  A ferramenta '$tool' não está instalada."
    echo "📦 Descrição: $description"
    echo "🔧 Comando de instalação: $install_cmd"
    echo ""
    read -p "Deseja instalar '$tool' agora? (s/N): " install_confirm
    
    if [[ "$install_confirm" =~ ^[Ss]$ ]]; then
        echo "🔄 Instalando $tool..."
        eval $install_cmd
        
        if [ $? -eq 0 ]; then
            echo "✅ $tool instalado com sucesso!"
            return 0
        else
            echo "❌ Erro ao instalar $tool"
            echo "💡 Dica: Execute o script como root para instalar pacotes"
            return 1
        fi
    else
        echo "Instalação cancelada pelo usuário."
        return 1
    fi
}

# Função para instalar lazydocker
install_lazydocker() {
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
    
    if [ $? -eq 0 ]; then
        tar -xzf lazydocker.tar.gz
        mv lazydocker /usr/local/bin/ 2>/dev/null || cp lazydocker ~/bin/ 2>/dev/null || cp lazydocker ~/.local/bin/
        chmod +x /usr/local/bin/lazydocker 2>/dev/null || chmod +x ~/bin/lazydocker 2>/dev/null || chmod +x ~/.local/bin/lazydocker
        rm -f lazydocker.tar.gz
        echo "✅ LazyDocker instalado com sucesso!"
        return 0
    else
        echo "❌ Erro ao baixar LazyDocker"
        return 1
    fi
}

# Função para instalar lazygit
install_lazygit() {
    echo "🔀 Instalando LazyGit..."
    
    # Obter última versão
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' 2>/dev/null || echo "0.40.2")
    
    # Baixar e instalar
    cd /tmp
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    
    if [ $? -eq 0 ]; then
        tar xf lazygit.tar.gz lazygit
        mv lazygit /usr/local/bin/ 2>/dev/null || cp lazygit ~/bin/ 2>/dev/null || cp lazygit ~/.local/bin/
        chmod +x /usr/local/bin/lazygit 2>/dev/null || chmod +x ~/bin/lazygit 2>/dev/null || chmod +x ~/.local/bin/lazygit
        rm -f lazygit.tar.gz lazygit
        echo "✅ LazyGit instalado com sucesso!"
        return 0
    else
        echo "❌ Erro ao baixar LazyGit"
        return 1
    fi
}

# Função para instalar pathmanager
install_pathmanager() {
    echo "📁 Instalando PathManager..."
    
    # Baixar do repositório
    wget -q "https://raw.githubusercontent.com/EriveltonLima/scripts/main/pathmanager.sh" -O /tmp/pathmanager.sh
    
    if [ -f "/tmp/pathmanager.sh" ]; then
        mv /tmp/pathmanager.sh /usr/local/bin/pathmanager 2>/dev/null || cp /tmp/pathmanager.sh ~/bin/pathmanager 2>/dev/null || cp /tmp/pathmanager.sh ~/.local/bin/pathmanager
        chmod +x /usr/local/bin/pathmanager 2>/dev/null || chmod +x ~/bin/pathmanager 2>/dev/null || chmod +x ~/.local/bin/pathmanager
        echo "✅ PathManager instalado com sucesso!"
        return 0
    else
        echo "❌ Erro ao baixar PathManager"
        return 1
    fi
}

# Função para mostrar o menu principal
show_menu() {
    clear
    echo "=============================================="
    echo "  FERRAMENTAS INTEGRADAS - DIAGNÓSTICO E UTILITÁRIOS"
    echo "  VERSÃO SEM SUDO - INSTALAÇÃO OPCIONAL"
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
    echo ""
    
    # Carregar e mostrar ferramentas adicionais
    load_additional_tools
    if [ ${#tools[@]} -gt 0 ]; then
        echo "=== FERRAMENTAS ADICIONAIS ==="
        for i in "${!tools[@]}"; do
            local tool_entry=${tools[$i]}
            local cmd=$(echo "$tool_entry" | cut -d'|' -f1)
            local desc=$(echo "$tool_entry" | cut -d'|' -f2)
            echo "$((i + 19))) 🔧 $cmd ($desc)"
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
                if offer_install "Node.js/npm" "apt update && apt install -y nodejs npm" "Ambiente JavaScript e gerenciador de pacotes"; then
                    run_command "npx speed-cloudflare-cli" "Teste de velocidade via Cloudflare"
                else
                    read -p "Pressione ENTER para continuar..."
                fi
            fi
            ;;
        2)
            if check_tool "speedtest-cli"; then
                run_command "speedtest-cli" "Teste de velocidade via Ookla"
            else
                if offer_install "speedtest-cli" "apt update && apt install -y speedtest-cli" "Cliente de teste de velocidade Ookla"; then
                    run_command "speedtest-cli" "Teste de velocidade via Ookla"
                else
                    read -p "Pressione ENTER para continuar..."
                fi
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
                if offer_install "nmap" "apt update && apt install -y nmap" "Scanner de rede e portas"; then
                    read -p "Digite o alvo para scan (ex: 192.168.1.0/24 ou 192.168.1.1): " target
                    if [ -n "$target" ]; then
                        run_command "nmap $target" "Scanner de rede - $target"
                    fi
                else
                    read -p "Pressione ENTER para continuar..."
                fi
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
                if offer_install "upower" "apt update && apt install -y upower" "Gerenciador de informações de energia"; then
                    run_command "upower -i \$(upower -e)" "Informações de energia"
                else
                    read -p "Pressione ENTER para continuar..."
                fi
            fi
            ;;
        8)
            if check_tool "sensors"; then
                run_command "sensors" "Sensores de hardware"
            else
                if offer_install "sensors" "apt update && apt install -y lm-sensors" "Sensores de temperatura e hardware"; then
                    run_command "sensors" "Sensores de hardware"
                else
                    read -p "Pressione ENTER para continuar..."
                fi
            fi
            ;;
        9)
            if check_tool "btop"; then
                echo "Executando btop - Monitor de sistema avançado..."
                btop
            else
                if offer_install "btop" "apt update && apt install -y btop" "Monitor de sistema avançado"; then
                    echo "Executando btop - Monitor de sistema avançado..."
                    btop
                else
                    read -p "Pressione ENTER para continuar..."
                fi
            fi
            ;;
        10)
            if check_tool "lazydocker"; then
                echo "Executando LazyDocker..."
                lazydocker
            else
                echo "⚠️  LazyDocker não encontrado."
                read -p "Deseja instalar LazyDocker? (s/N): " install_confirm
                if [[ "$install_confirm" =~ ^[Ss]$ ]]; then
                    if install_lazydocker; then
                        echo "Executando LazyDocker..."
                        lazydocker
                    fi
                fi
            fi
            ;;
        11)
            if check_tool "lazygit"; then
                echo "Executando LazyGit..."
                lazygit
            else
                echo "⚠️  LazyGit não encontrado."
                read -p "Deseja instalar LazyGit? (s/N): " install_confirm
                if [[ "$install_confirm" =~ ^[Ss]$ ]]; then
                    if install_lazygit; then
                        echo "Executando LazyGit..."
                        lazygit
                    fi
                fi
            fi
            ;;
        12)
            if check_tool "pathmanager"; then
                echo "Executando PathManager..."
                pathmanager
                read -p "Pressione ENTER para continuar..."
            else
                echo "⚠️  PathManager não encontrado."
                read -p "Deseja instalar PathManager? (s/N): " install_confirm
                if [[ "$install_confirm" =~ ^[Ss]$ ]]; then
                    if install_pathmanager; then
                        echo "Executando PathManager..."
                        pathmanager
                        read -p "Pressione ENTER para continuar..."
                    fi
                fi
            fi
            ;;
        13)
            if check_tool "tree"; then
                run_command "tree" "Árvore de arquivos"
            else
                if offer_install "tree" "apt update && apt install -y tree" "Visualizador de árvore de diretórios"; then
                    run_command "tree" "Árvore de arquivos"
                else
                    read -p "Pressione ENTER para continuar..."
                fi
            fi
            ;;
        14)
            run_command "pwd && ls -la" "Diretório atual e conteúdo"
            ;;
        15)
            if check_tool "mc"; then
                echo "Executando Midnight Commander..."
                mc
            else
                if offer_install "mc" "apt update && apt install -y mc" "Gerenciador de arquivos Midnight Commander"; then
                    echo "Executando Midnight Commander..."
                    mc
                else
                    read -p "Pressione ENTER para continuar..."
                fi
            fi
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
        0)
            echo "Saindo do script..."
            exit 0
            ;;
        *)
            # Verificar se é uma ferramenta adicional
            load_additional_tools
            if [[ $option =~ ^[0-9]+$ ]] && [ "$option" -ge 19 ]; then
                idx=$((option - 19))
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
