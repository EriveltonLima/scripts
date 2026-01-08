#!/bin/bash
# Script para executar DENTRO do container LXC
# enable_ssh_inside_container.sh

echo "=== Configurando SSH Root (Executando dentro do container) ==="

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script deve ser executado como root!"
    echo "Use: sudo $0"
    exit 1
fi

# Solicitar nova senha
echo "🔐 Digite a nova senha para o usuário root:"
read -s new_password
echo ""
echo "🔐 Confirme a senha:"
read -s confirm_password
echo ""

if [ "$new_password" != "$confirm_password" ]; then
    echo "❌ As senhas não coincidem!"
    exit 1
fi

# Alterar senha do root
echo "📝 Alterando senha do root..."
echo "root:$new_password" | chpasswd
if [ $? -eq 0 ]; then
    echo "✅ Senha alterada com sucesso!"
else
    echo "❌ Erro ao alterar senha!"
    exit 1
fi

# Backup da configuração SSH
if [ ! -f /etc/ssh/sshd_config.backup ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    echo "📋 Backup criado: /etc/ssh/sshd_config.backup"
fi

# Configurar SSH
echo "🔧 Configurando SSH..."
sed -i "/^#*PermitRootLogin/c\PermitRootLogin yes" /etc/ssh/sshd_config
if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
fi

sed -i "/^#*PasswordAuthentication/c\PasswordAuthentication yes" /etc/ssh/sshd_config
if ! grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
fi

# Reiniciar SSH
echo "🔄 Reiniciando serviço SSH..."
systemctl restart sshd || service ssh restart

if systemctl is-active sshd >/dev/null 2>&1 || systemctl is-active ssh >/dev/null 2>&1; then
    echo "✅ SSH configurado com sucesso!"
    
    # Mostrar IP do container
    container_ip=$(hostname -I | awk '{print $1}')
    if [ ! -z "$container_ip" ]; then
        echo "🌐 IP do container: $container_ip"
        echo "🔗 Teste com: ssh root@$container_ip"
    fi
else
    echo "❌ Erro ao reiniciar SSH!"
    exit 1
fi

echo "✅ Configuração concluída!"
