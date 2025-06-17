#!/bin/bash

# Script de Otimização de Velocidade - Versão Corrigida
# Compatível com containers e sistemas sem fstab

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

title() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Verificar se é root
if [[ $EUID -ne 0 ]]; then
   error "Este script deve ser executado como root"
   exit 1
fi

# Detectar distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION_CODENAME=$VERSION_CODENAME
else
    error "Não foi possível detectar a distribuição"
    exit 1
fi

log "Sistema detectado: $DISTRO $VERSION_CODENAME"

# Detectar se é container
IS_CONTAINER=false
if [ -f /.dockerenv ] || [ -f /run/.containerenv ] || grep -q "container" /proc/1/cgroup 2>/dev/null; then
    IS_CONTAINER=true
    warn "Sistema container detectado - algumas otimizações serão adaptadas"
fi

# Backup de arquivos importantes
BACKUP_DIR="/root/backup-otimizacao-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
log "Backup será salvo em: $BACKUP_DIR"

# Função para fazer backup seguro
backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$BACKUP_DIR/"
        log "Backup criado: $1"
        return 0
    else
        warn "Arquivo não encontrado: $1"
        return 1
    fi
}

title "1. OTIMIZAÇÃO DO APT"

# Backup de arquivos APT
backup_file "/etc/apt/sources.list"

# Configurar mirrors mais rápidos
log "Configurando mirrors brasileiros rápidos..."

if [ "$DISTRO" = "debian" ]; then
    cat > /etc/apt/sources.list << EOF
# Mirrors brasileiros otimizados - Debian $VERSION_CODENAME
deb http://debian.c3sl.ufpr.br/debian/ $VERSION_CODENAME main contrib non-free non-free-firmware
deb http://debian.c3sl.ufpr.br/debian/ $VERSION_CODENAME-updates main contrib non-free non-free-firmware
deb http://debian.c3sl.ufpr.br/debian-security/ $VERSION_CODENAME-security main contrib non-free non-free-firmware
deb http://debian.c3sl.ufpr.br/debian/ $VERSION_CODENAME-backports main contrib non-free non-free-firmware
EOF
elif [ "$DISTRO" = "ubuntu" ]; then
    cat > /etc/apt/sources.list << EOF
# Mirrors brasileiros otimizados - Ubuntu $VERSION_CODENAME
deb http://br.archive.ubuntu.com/ubuntu/ $VERSION_CODENAME main restricted universe multiverse
deb http://br.archive.ubuntu.com/ubuntu/ $VERSION_CODENAME-updates main restricted universe multiverse
deb http://br.archive.ubuntu.com/ubuntu/ $VERSION_CODENAME-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ $VERSION_CODENAME-security main restricted universe multiverse
EOF
fi

# Otimizações APT
log "Configurando otimizações do APT..."
cat > /etc/apt/apt.conf.d/99speedup << EOF
# Otimizações de velocidade APT
Acquire::http::Timeout "60";
Acquire::https::Timeout "60";
Acquire::ftp::Timeout "60";
Acquire::Retries "3";
Acquire::http::Pipeline-Depth "5";
Acquire::http::Max-Age "86400";
Acquire::Languages "none";
APT::Get::Show-Upgraded "true";
APT::Get::Show-Versions "false";
APT::Cache-Start "32000000";
APT::Cache-Grow "2048000";
APT::Cache-Limit "100000000";
Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";
EOF

# Desabilitar IPv6 se causar problemas
log "Configurando preferência IPv4..."
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

title "2. OTIMIZAÇÃO DE REDE"

# Otimizações TCP/IP (apenas se não for container)
if [ "$IS_CONTAINER" = false ]; then
    log "Aplicando otimizações de rede..."
    cat >> /etc/sysctl.conf << EOF

# Otimizações de rede adicionadas em $(date)
# TCP Window Scaling
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

# TCP Congestion Control
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# Reduzir tempo de timeout
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Otimizações gerais
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_no_metrics_save = 1
EOF
else
    warn "Otimizações de rede puladas (sistema container)"
fi

# Configurar DNS mais rápidos
log "Configurando DNS rápidos..."
backup_file "/etc/resolv.conf"
cat > /etc/resolv.conf << EOF
# DNS otimizados para velocidade
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
options timeout:2 attempts:3 rotate single-request-reopen
EOF

title "3. OTIMIZAÇÃO DO SISTEMA"

# Otimizações do kernel (apenas se não for container)
if [ "$IS_CONTAINER" = false ]; then
    log "Aplicando otimizações do kernel..."
    cat >> /etc/sysctl.conf << EOF

# Otimizações de sistema
# Reduzir swappiness
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Otimizações de I/O
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_expire_centisecs = 1500
vm.dirty_writeback_centisecs = 500

# Otimizações de memória
vm.min_free_kbytes = 65536
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
EOF
else
    warn "Otimizações de kernel puladas (sistema container)"
fi

title "4. OTIMIZAÇÃO DE I/O E DISCO"

# Configurar I/O scheduler (apenas se não for container)
if [ "$IS_CONTAINER" = false ]; then
    log "Configurando I/O scheduler..."
    cat > /etc/udev/rules.d/60-ioschedulers.rules << EOF
# Otimizar I/O schedulers
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
EOF
else
    warn "Configuração I/O scheduler pulada (sistema container)"
fi

# Configurar fstab para melhor performance (apenas se existir)
if [ -f /etc/fstab ]; then
    log "Otimizando opções de montagem..."
    backup_file "/etc/fstab"
    sed -i 's/errors=remount-ro/errors=remount-ro,noatime,commit=60/' /etc/fstab
else
    warn "Arquivo /etc/fstab não encontrado - otimizações de montagem puladas"
fi

title "5. OTIMIZAÇÃO DE SERVIÇOS"

# Desabilitar serviços desnecessários (apenas se não for container)
if [ "$IS_CONTAINER" = false ]; then
    log "Otimizando serviços do sistema..."
    SERVICES_TO_DISABLE=(
        "bluetooth.service"
        "cups.service"
        "avahi-daemon.service"
        "ModemManager.service"
    )

    for service in "${SERVICES_TO_DISABLE[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            systemctl disable "$service" >/dev/null 2>&1
            log "Serviço desabilitado: $service"
        fi
    done
else
    warn "Otimização de serviços pulada (sistema container)"
fi

# Configurar journald para usar menos espaço
if [ -d /etc/systemd/journald.conf.d/ ] || mkdir -p /etc/systemd/journald.conf.d/ 2>/dev/null; then
    log "Otimizando journald..."
    cat > /etc/systemd/journald.conf.d/99-speedup.conf << EOF
[Journal]
SystemMaxUse=100M
SystemMaxFileSize=10M
MaxRetentionSec=1week
Compress=yes
EOF
else
    warn "Não foi possível configurar journald"
fi

title "6. OTIMIZAÇÃO DE BOOT"

# Reduzir timeout do GRUB (apenas se não for container)
if [ "$IS_CONTAINER" = false ] && [ -f /etc/default/grub ]; then
    log "Otimizando tempo de boot..."
    backup_file "/etc/default/grub"
    sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
    sed -i 's/#GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
    if command -v update-grub >/dev/null 2>&1; then
        update-grub >/dev/null 2>&1
    fi
else
    warn "Otimização de boot pulada (sistema container ou GRUB não encontrado)"
fi

title "7. LIMPEZA E MANUTENÇÃO"

# Limpeza do sistema
log "Executando limpeza do sistema..."
apt update >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1
apt autoclean >/dev/null 2>&1

# Limpar logs antigos
if command -v journalctl >/dev/null 2>&1; then
    journalctl --vacuum-time=7d >/dev/null 2>&1
    journalctl --vacuum-size=100M >/dev/null 2>&1
fi

# Limpar cache
find /tmp -type f -atime +7 -delete 2>/dev/null || true
find /var/tmp -type f -atime +7 -delete 2>/dev/null || true

title "8. CONFIGURAÇÕES FINAIS"

# Aplicar configurações sysctl (apenas se não for container)
if [ "$IS_CONTAINER" = false ]; then
    sysctl -p >/dev/null 2>&1
fi

# Criar script de manutenção automática
log "Criando script de manutenção automática..."
cat > /usr/local/bin/sistema-manutencao << 'MAINT_EOF'
#!/bin/bash
# Script de manutenção automática
echo "=== Manutenção do Sistema - $(date) ==="
apt update && apt upgrade -y
apt autoremove -y && apt autoclean
if command -v journalctl >/dev/null 2>&1; then
    journalctl --vacuum-time=7d
    journalctl --vacuum-size=100M
fi
sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
echo "Manutenção concluída!"
MAINT_EOF

chmod +x /usr/local/bin/sistema-manutencao

# Configurar cron para manutenção semanal (apenas se não for container)
if [ "$IS_CONTAINER" = false ] && command -v crontab >/dev/null 2>&1; then
    (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/local/bin/sistema-manutencao >> /var/log/manutencao.log 2>&1") | crontab -
fi

title "OTIMIZAÇÃO CONCLUÍDA"

log "Otimizações aplicadas com sucesso!"
echo ""
echo "=== RESUMO DAS OTIMIZAÇÕES ==="
echo "✓ Mirrors brasileiros configurados"
echo "✓ Configurações APT otimizadas"
echo "✓ DNS rápidos configurados"
if [ "$IS_CONTAINER" = false ]; then
    echo "✓ Parâmetros de rede otimizados"
    echo "✓ I/O schedulers configurados"
    echo "✓ Serviços desnecessários desabilitados"
fi
echo "✓ Journald otimizado"
echo "✓ Sistema limpo e otimizado"
echo "✓ Manutenção automática configurada"
echo ""
warn "Backup salvo em: $BACKUP_DIR"
if [ "$IS_CONTAINER" = false ]; then
    warn "REINICIE o sistema para aplicar todas as otimizações!"
else
    warn "Reinicie o container para aplicar as otimizações de rede"
fi

