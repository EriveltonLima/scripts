#!/bin/bash

# Script para atualização completa do sistema e configuração do repositório
# Autor: Erivelton de Lima da Cruz
# Data: $(date)

echo "=========================================="
echo "AUTOMAÇÃO COMPLETA DO SISTEMA"
echo "=========================================="
echo "1. Atualizando sistema completo"
echo "2. Clonando repositório de scripts"
echo "3. Executando speed-apt.sh"
echo "=========================================="

# Função para verificar se o comando foi executado com sucesso
check_status() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 - Concluído com sucesso!"
    else
        echo "❌ $1 - Erro durante a execução!"
        exit 1
    fi
}

# ETAPA 1: Atualização completa do sistema
echo "🔄 Iniciando atualização completa do sistema..."

# Atualizar lista de repositórios
echo "Atualizando lista de repositórios..."
apt update
check_status "Atualização da lista de repositórios"

# Upgrade dos pacotes instalados
echo "Atualizando pacotes instalados..."
apt upgrade -y
check_status "Upgrade de pacotes"

# Upgrade completo (incluindo novos pacotes se necessário)
echo "Executando upgrade completo..."
apt full-upgrade -y
check_status "Full upgrade"

# Limpeza de pacotes desnecessários
echo "Removendo pacotes desnecessários..."
apt --purge autoremove -y
check_status "Limpeza de pacotes"

# Limpeza do cache
echo "Limpando cache do APT..."
apt autoclean
check_status "Limpeza de cache"

echo "✅ Sistema completamente atualizado!"

# ETAPA 2: Clonagem do repositório
echo "🔄 Clonando repositório de scripts..."

# Verificar se git está instalado
if ! command -v git &> /dev/null; then
    echo "Git não encontrado. Instalando..."
    apt install -y git
    check_status "Instalação do Git"
fi

# Remover diretório se já existir
if [ -d "scripts" ]; then
    echo "Removendo diretório scripts existente..."
    rm -rf scripts
fi

# Clonar o repositório
git clone https://github.com/EriveltonLima/scripts.git
check_status "Clonagem do repositório"

# Entrar no diretório
cd scripts
check_status "Acesso ao diretório scripts"

# Dar permissões de execução para todos os scripts
echo "Configurando permissões dos scripts..."
chmod +x *.sh
check_status "Configuração de permissões"

echo "✅ Repositório clonado e configurado!"

# ETAPA 3: Executar speed-apt.sh
echo "🔄 Executando script speed-apt.sh..."

# Verificar se o script existe
if [ -f "speed-apt.sh" ]; then
    echo "Executando speed-apt.sh..."
    ./speed-apt.sh
    check_status "Execução do speed-apt.sh"
else
    echo "❌ Script speed-apt.sh não encontrado no repositório!"
    exit 1
fi

echo "=========================================="
echo "🎉 AUTOMAÇÃO CONCLUÍDA COM SUCESSO!"
echo "=========================================="
echo "✅ Sistema completamente atualizado"
echo "✅ Repositório clonado em: $(pwd)"
echo "✅ Script speed-apt.sh executado"
echo "✅ Sistema otimizado e pronto para uso"
echo "=========================================="

# Mostrar informações do sistema
echo "📊 INFORMAÇÕES DO SISTEMA:"
echo "Versão do Debian: $(cat /etc/debian_version)"
echo "Kernel: $(uname -r)"
echo "Espaço em disco disponível:"
df -h / | tail -1

echo "🔄 Recomenda-se reiniciar o sistema para aplicar todas as atualizações:"
echo "sudo reboot"
