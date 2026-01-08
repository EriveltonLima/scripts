#!/bin/bash

# Verificar se está executando como root ou com sudo
if [[ $EUID -eq 0 ]]; then
    # Se for root, instalar em /usr/local/bin
    DIR="${DIR:-"/usr/local/bin"}"
else
    # Se não for root, verificar se sudo está disponível
    if command -v sudo >/dev/null 2>&1; then
        echo "Instalação requer privilégios de administrador. Usando sudo..."
        DIR="${DIR:-"/usr/local/bin"}"
        SUDO="sudo"
    else
        # Fallback para ~/.local/bin se sudo não estiver disponível
        DIR="${DIR:-"$HOME/.local/bin"}"
        echo "Aviso: Instalando em $DIR - você pode precisar adicionar ao PATH"
    fi
fi

# Criar diretório se não existir
mkdir -p "$DIR"

# map different architecture variations to the available binaries
ARCH=$(uname -m)
case $ARCH in
    i386|i686) ARCH=x86 ;;
    armv6*) ARCH=armv6 ;;
    armv7*) ARCH=armv7 ;;
    aarch64*) ARCH=arm64 ;;
esac

# prepare the download URL
echo "Obtendo a versão mais recente do LazyDocker..."
GITHUB_LATEST_VERSION=$(curl -L -s -H 'Accept: application/json' https://github.com/jesseduffield/lazydocker/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
GITHUB_FILE="lazydocker_${GITHUB_LATEST_VERSION//v/}_$(uname -s)_${ARCH}.tar.gz"
GITHUB_URL="https://github.com/jesseduffield/lazydocker/releases/download/${GITHUB_LATEST_VERSION}/${GITHUB_FILE}"

echo "Baixando LazyDocker versão $GITHUB_LATEST_VERSION..."

# install/update the local binary
curl -L -o lazydocker.tar.gz $GITHUB_URL
tar xzvf lazydocker.tar.gz lazydocker

# Instalar com sudo se necessário
if [[ -n "$SUDO" ]]; then
    $SUDO install -Dm 755 lazydocker -t "$DIR"
else
    install -Dm 755 lazydocker -t "$DIR"
fi

# Limpar arquivos temporários
rm lazydocker lazydocker.tar.gz

echo "LazyDocker instalado com sucesso em $DIR"

# Verificar se está no PATH
if [[ "$DIR" == "/usr/local/bin" ]] || [[ "$DIR" == "/usr/bin" ]]; then
    echo "✅ LazyDocker está disponível globalmente. Execute: lazydocker"
else
    # Verificar se ~/.local/bin está no PATH
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        echo "✅ LazyDocker está disponível. Execute: lazydocker"
    else
        echo "⚠️  Para usar o LazyDocker globalmente, adicione ao seu PATH:"
        echo "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
        echo "   source ~/.bashrc"
        echo "   Ou execute diretamente: $DIR/lazydocker"
    fi
fi

# Verificar se o Docker está instalado e rodando
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker está rodando"
    else
        echo "⚠️  Docker está instalado mas não está rodando"
        echo "   Execute: sudo systemctl start docker"
    fi
else
    echo "⚠️  Docker não está instalado"
fi

# Verificar permissões do Docker para o usuário atual
if [[ $EUID -ne 0 ]] && ! groups | grep -q docker; then
    echo "💡 Dica: Para usar o LazyDocker sem sudo, adicione seu usuário ao grupo docker:"
    echo "   sudo usermod -aG docker $USER"
    echo "   Depois faça logout e login novamente"
fi
