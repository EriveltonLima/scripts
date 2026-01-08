#!/bin/bash
# Pangolin Blueprint Generator - Installer
# Usage: curl -fsSL <URL> | bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════╗"
echo "║   Pangolin Blueprint Generator - Installer   ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# Install dependencies
echo -e "${YELLOW}[1/4] Instalando dependências...${NC}"
apt-get update -qq
apt-get install -y -qq jq whiptail > /dev/null 2>&1 || {
    echo "Não foi possível instalar dependências. Tentando yum..."
    yum install -y jq newt > /dev/null 2>&1
}

# Create directory
echo -e "${YELLOW}[2/4] Criando diretório...${NC}"
mkdir -p /opt/pangolin-blueprint

# Download script
echo -e "${YELLOW}[3/4] Baixando script...${NC}"
cat > /opt/pangolin-blueprint/gen_blueprint.sh << 'SCRIPT'
#!/bin/bash
# Pangolin Blueprint Generator - TUI Version

set -e

GREEN='\033[0;32m'
NC='\033[0m'

for cmd in whiptail jq docker; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is required but not installed."
        exit 1
    fi
done

BASE_DOMAIN=$(whiptail --inputbox "Digite o domínio base:" 8 50 "homlab.site" --title "Pangolin Blueprint Generator" 3>&1 1>&2 2>&3)
[ -z "$BASE_DOMAIN" ] && exit 1

OUTPUT_FILE=$(whiptail --inputbox "Arquivo de saída:" 8 50 "blueprint.yaml" --title "Arquivo de Saída" 3>&1 1>&2 2>&3)
[ -z "$OUTPUT_FILE" ] && OUTPUT_FILE="blueprint.yaml"

CONTAINERS=()
while read -r line; do
    NAME=$(echo "$line" | cut -d'|' -f1)
    PORTS=$(echo "$line" | cut -d'|' -f2)
    [ -n "$PORTS" ] && CONTAINERS+=("$NAME" "$PORTS" "ON")
done < <(docker ps --format '{{.Names}}|{{.Ports}}' | grep -v "^$")

if [ ${#CONTAINERS[@]} -eq 0 ]; then
    whiptail --msgbox "Nenhum container com portas mapeadas encontrado!" 8 50
    exit 1
fi

SELECTED=$(whiptail --checklist "Selecione os containers para incluir:" 20 70 10 "${CONTAINERS[@]}" --title "Containers Disponíveis" 3>&1 1>&2 2>&3)
[ -z "$SELECTED" ] && exit 1

SELECTED=$(echo "$SELECTED" | tr -d '"')

echo "proxy-resources:" > "$OUTPUT_FILE"

for CONTAINER in $SELECTED; do
    PORTS=$(docker inspect "$CONTAINER" --format '{{json .NetworkSettings.Ports}}' | jq -r 'to_entries[] | select(.value != null) | .value[] | "\(.HostPort)"' 2>/dev/null | sort -u)
    VHOST=$(docker inspect "$CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' | grep "^VIRTUAL_HOST=" | cut -d= -f2)
    
    for PORT in $PORTS; do
        [ -z "$PORT" ] && continue
        
        RESOURCE_ID="resource-${CONTAINER}-${PORT}"
        grep -q "^  ${RESOURCE_ID}:" "$OUTPUT_FILE" 2>/dev/null && continue
        
        if [ -n "$VHOST" ]; then
            FULL_DOMAIN="$VHOST"
        else
            FULL_DOMAIN="${CONTAINER}.${BASE_DOMAIN}"
        fi
        
        cat >> "$OUTPUT_FILE" <<EOF
  ${RESOURCE_ID}:
    name: ${CONTAINER} service port ${PORT}
    protocol: http
    full-domain: ${FULL_DOMAIN}
    targets:
      - site: ${CONTAINER}
        hostname: localhost
        method: http
        port: ${PORT}
EOF
    done
done

whiptail --title "Blueprint Gerado!" --scrolltext --textbox "$OUTPUT_FILE" 20 70
echo -e "${GREEN}[✓] Blueprint salvo em: $OUTPUT_FILE${NC}"
SCRIPT

chmod +x /opt/pangolin-blueprint/gen_blueprint.sh

# Create symlink
echo -e "${YELLOW}[4/4] Criando comando global...${NC}"
ln -sf /opt/pangolin-blueprint/gen_blueprint.sh /usr/local/bin/pangolin-blueprint

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗"
echo "║         Instalação concluída! ✓              ║"
echo "╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "Para usar, execute:"
echo "  pangolin-blueprint"
echo ""
