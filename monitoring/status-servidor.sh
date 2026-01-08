#!/bin/bash

# Script para exibir informações de sensores e status da bateria de forma organizada

# Cores (opcional, remova se preferir sem cores)
BLUE_BOLD='\033[1;34m'
GREEN_BOLD='\033[1;32m'
YELLOW_BOLD='\033[1;33m'
WHITE_BOLD='\033[1;37m'
NC='\033[0m' # No Color

echo -e "${BLUE_BOLD}===========================================${NC}"
echo -e "${BLUE_BOLD}   INFORMAÇÕES DE TEMPERATURA (SENSORS)  ${NC}"
echo -e "${BLUE_BOLD}===========================================${NC}"

# Extrai e formata as temperaturas principais
# Nota: A ordem e o nome exato dos sensores podem variar um pouco.
# Ajuste os comandos grep/awk se necessário para o seu sistema.
sensors_output=$(sensors)

package_temp=$(echo "$sensors_output" | grep -i 'Package id 0:' | awk '{print $4}')
core0_temp=$(echo "$sensors_output" | grep -i 'Core 0:' | awk '{print $3}')
# Para o "Core 2" que na verdade é o segundo núcleo físico do seu Celeron N3350
core_next_label=$(echo "$sensors_output" | grep -iE 'Core [1-9]:|Core [1-9][0-9]:' | head -n 1 | awk -F':' '{print $1}' | sed 's/^[ \t]*//;s/[ \t]*$//')
core_next_temp=$(echo "$sensors_output" | grep -iE 'Core [1-9]:|Core [1-9][0-9]:' | head -n 1 | awk '{print $3}')

acpitz_temp1_label="Placa-mãe/Ambiente (acpitz temp1)"
acpitz_temp1_val=$(echo "$sensors_output" | grep -i 'temp1:' | grep -i 'acpitz' | awk '{print $2}')

if [ -n "$package_temp" ]; then
  printf "${WHITE_BOLD}%-35s${NC} %s\n" "CPU (Package Total):" "${package_temp}"
fi
if [ -n "$core0_temp" ]; then
  printf "${WHITE_BOLD}%-35s${NC} %s\n" "CPU (Core 0):" "${core0_temp}"
fi
if [ -n "$core_next_temp" ]; then
  printf "${WHITE_BOLD}%-35s${NC} %s\n" "CPU ($core_next_label):" "${core_next_temp}"
fi
if [ -n "$acpitz_temp1_val" ]; then
  printf "${WHITE_BOLD}%-35s${NC} %s\n" "$acpitz_temp1_label:" "${acpitz_temp1_val}"
fi

echo # Linha em branco

echo -e "${GREEN_BOLD}===========================================${NC}"
echo -e "${GREEN_BOLD}    STATUS DA BATERIA (UPOWER)           ${NC}"
echo -e "${GREEN_BOLD}===========================================${NC}"

battery_path="/org/freedesktop/UPower/devices/battery_BAT0"
# Verifica se o dispositivo de bateria existe antes de tentar ler
if upower -e | grep -q "$battery_path"; then
    upower_output=$(upower -i "$battery_path")

    state=$(echo "$upower_output" | grep -i 'state:' | awk -F': ' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    percentage=$(echo "$upower_output" | grep -i 'percentage:' | awk -F': ' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    capacity=$(echo "$upower_output" | grep -i 'capacity:' | awk -F': ' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    energy_full=$(echo "$upower_output" | grep -i 'energy-full:' | awk -F': ' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    energy_full_design=$(echo "$upower_output" | grep -i 'energy-full-design:' | awk -F': ' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    energy_rate=$(echo "$upower_output" | grep -i 'energy-rate:' | awk -F': ' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    voltage=$(echo "$upower_output" | grep -i 'voltage:' | awk -F': ' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')

    printf "${WHITE_BOLD}%-35s${NC} %s\n" "Estado:" "${state}"
    printf "${WHITE_BOLD}%-35s${NC} %s\n" "Nível de Carga:" "${percentage}"
    printf "${WHITE_BOLD}%-35s${NC} %s\n" "Saúde da Bateria (Capacidade):" "${capacity}"
    printf "${WHITE_BOLD}%-35s${NC} %s\n" "Carga Máxima Atual:" "${energy_full}"
    printf "${WHITE_BOLD}%-35s${NC} %s\n" "Carga Máxima de Fábrica:" "${energy_full_design}"
    if [[ "$energy_rate" != "0 W" && "$energy_rate" != "0,0 W" ]]; then # Só mostra se não for 0W
      printf "${WHITE_BOLD}%-35s${NC} %s\n" "Taxa de Consumo/Carga:" "${energy_rate}"
    fi
    printf "${WHITE_BOLD}%-35s${NC} %s\n" "Voltagem:" "${voltage}"
else
    echo -e "${YELLOW_BOLD}Dispositivo de bateria $battery_path não encontrado.${NC}"
fi

echo # Linha em branco
echo -e "${BLUE_BOLD}===========================================${NC}"
echo -e "${BLUE_BOLD}              FIM DO RELATÓRIO             ${NC}"
echo -e "${BLUE_BOLD}===========================================${NC}"
