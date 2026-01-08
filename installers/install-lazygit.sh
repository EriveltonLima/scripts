#!/bin/bash
echo "Instalando LazyGit..."

# Verificar dependências
if ! command -v curl >/dev/null 2>&1; then
    echo "Instalando curl..."
    sudo apt update
    sudo apt install -y curl
fi

# Obter e instalar LazyGit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
echo "Baixando LazyGit versão $LAZYGIT_VERSION..."

curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/
rm lazygit.tar.gz lazygit

echo "✅ LazyGit instalado com sucesso!"
lazygit --version
