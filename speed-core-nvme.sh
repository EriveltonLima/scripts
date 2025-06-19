#!/bin/bash

# Script Interativo para Comparação de Load Average - VERSÃO PRÉ-CONFIGURADA
# Configurações já definidas para evitar problemas de input

# Configurações FIXAS (pré-definidas)
SCRIPT_DIR="/tmp/load_comparison"
LOG_FILE="$SCRIPT_DIR/load_comparison.log"
RESULTS_FILE="$SCRIPT_DIR/comparison_results.txt"

# CONFIGURAÇÕES DOS TESTES (PRÉ-DEFINIDAS)
TEST_DURATION=300        # 5 minutos
SAMPLE_INTERVAL=10       # 10 segundos
CPU_WORKERS=$(nproc)     # Número de cores
RUN_CPU_TEST=true
RUN_IO_TEST=true

# Cores para output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    PURPLE='\033[0;35m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    PURPLE=''
    NC=''
fi

# Função para exibir banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "============================================================"
    echo "              COMPARADOR DE LOAD AVERAGE                   "
    echo "          Analise de Performance do Sistema                "
    echo "============================================================"
    echo -e "${NC}"
    echo ""
}

# Função para pausar
pause() {
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read -r
}

# Função para confirmar ação
confirm_action() {
    local message="$1"
    local response
    
    while true; do
        echo -e "${YELLOW}$message (s/n): ${NC}"
        read -r response
        case "$response" in
            [Ss]|[Yy]) 
                return 0
                ;;
            [Nn]) 
                return 1
                ;;
            *) 
                echo -e "${RED}Por favor, responda 's' para sim ou 'n' para nao.${NC}"
                ;;
        esac
    done
}

# Função para configurar ambiente
setup_environment() {
    echo -e "${BLUE}Configurando ambiente...${NC}"
    mkdir -p "$SCRIPT_DIR"
    echo "$(date): Iniciando script de comparacao" > "$LOG_FILE"
    echo -e "${GREEN}Ambiente configurado!${NC}"
    echo ""
}

# Função para verificar dependências
check_dependencies() {
    echo -e "${BLUE}Verificando dependencias...${NC}"
    
    local missing_deps=()
    
    if ! command -v stress-ng >/dev/null 2>&1; then
        missing_deps+=("stress-ng")
    fi
    
    if ! command -v iostat >/dev/null 2>&1; then
        missing_deps+=("sysstat")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Instalando dependencias faltando...${NC}"
        apt-get update >/dev/null 2>&1
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                "stress-ng") apt-get install -y stress-ng >/dev/null 2>&1;;
                "sysstat") apt-get install -y sysstat >/dev/null 2>&1;;
            esac
        done
        echo -e "${GREEN}Dependencias instaladas!${NC}"
    else
        echo -e "${GREEN}Todas as dependencias OK!${NC}"
    fi
    echo ""
}

# Função para mostrar configurações
show_config() {
    echo -e "${CYAN}CONFIGURACOES DOS TESTES:${NC}"
    echo "========================================"
    echo "Duracao de cada teste: $TEST_DURATION segundos"
    echo "Intervalo de coleta: $SAMPLE_INTERVAL segundos"
    echo "CPU Workers: $CPU_WORKERS"
    echo "Teste de CPU: $RUN_CPU_TEST"
    echo "Teste de I/O: $RUN_IO_TEST"
    echo ""
}

# Função para mostrar informações do sistema
show_system_info() {
    echo -e "${BLUE}INFORMACOES DO SISTEMA${NC}"
    echo "========================================"
    
    local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
    local cpu_cores=$(nproc)
    local total_mem=$(free -h | grep "Mem:" | awk '{print $2}')
    local current_load=$(cat /proc/loadavg)
    
    echo "CPU: $cpu_model"
    echo "Cores: $cpu_cores"
    echo "Memoria: $total_mem"
    echo "Load Atual: $current_load"
    echo ""
    
    echo "Discos principais:"
    lsblk -d -o NAME,SIZE,TYPE 2>/dev/null | head -5
    echo ""
    
    pause
}

# Função para executar teste com progresso
run_test_with_progress() {
    local test_name="$1"
    local duration="$2"
    local stress_cmd="$3"
    local output_file="$4"
    
    echo -e "${YELLOW}Executando $test_name...${NC}"
    echo "Duracao: $duration segundos"
    echo ""
    
    # Preparar arquivo de saída
    echo "timestamp,load_1min,load_5min,load_15min" > "$output_file"
    
    # Iniciar stress test em background
    eval "$stress_cmd" >/dev/null 2>&1 &
    local stress_pid=$!
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local sample_count=0
    
    echo "Iniciando coleta de dados..."
    
    while [ $(date +%s) -lt $end_time ]; do
        sample_count=$((sample_count + 1))
        
        # Coletar load average
        local current_load=$(cat /proc/loadavg)
        local load_1=$(echo $current_load | awk '{print $1}')
        local load_5=$(echo $current_load | awk '{print $2}')
        local load_15=$(echo $current_load | awk '{print $3}')
        
        # Salvar dados
        echo "$(date +%s),$load_1,$load_5,$load_15" >> "$output_file"
        
        # Mostrar progresso
        local elapsed=$(($(date +%s) - start_time))
        local progress=$((elapsed * 100 / duration))
        echo "Progresso: $progress% - Load: $load_1"
        
        sleep $SAMPLE_INTERVAL
    done
    
    # Finalizar stress test
    kill $stress_pid 2>/dev/null
    wait $stress_pid 2>/dev/null
    
    echo -e "${GREEN}$test_name concluido!${NC}"
    echo "Dados salvos em: $output_file"
    echo ""
}

# Função para executar bateria de testes
run_test_battery() {
    local phase="$1"
    
    echo -e "${PURPLE}INICIANDO BATERIA DE TESTES - ${phase^^}${NC}"
    echo "=============================================="
    echo ""
    
    show_config
    
    if confirm_action "Pronto para iniciar os testes?"; then
        echo ""
        
        # Teste de CPU
        if [ "$RUN_CPU_TEST" = "true" ]; then
            echo -e "${CYAN}=== TESTE DE CPU ===${NC}"
            local cpu_cmd="stress-ng --cpu $CPU_WORKERS --timeout ${TEST_DURATION}s"
            run_test_with_progress "Teste de CPU" "$TEST_DURATION" "$cpu_cmd" "$SCRIPT_DIR/cpu_test_$phase.tmp"
            
            # Pausa entre testes
            if [ "$RUN_IO_TEST" = "true" ]; then
                echo -e "${BLUE}Aguardando 30 segundos entre testes...${NC}"
                sleep 30
            fi
        fi
        
        # Teste de I/O
        if [ "$RUN_IO_TEST" = "true" ]; then
            echo -e "${CYAN}=== TESTE DE I/O ===${NC}"
            local io_cmd="stress-ng --io 4 --hdd 2 --timeout ${TEST_DURATION}s"
            run_test_with_progress "Teste de I/O" "$TEST_DURATION" "$io_cmd" "$SCRIPT_DIR/io_test_$phase.tmp"
        fi
        
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Bateria de testes '$phase' CONCLUIDA!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        
        # Mostrar resumo
        echo -e "${CYAN}RESUMO DOS ARQUIVOS GERADOS:${NC}"
        if [ -f "$SCRIPT_DIR/cpu_test_$phase.tmp" ]; then
            local cpu_samples=$(wc -l < "$SCRIPT_DIR/cpu_test_$phase.tmp")
            echo "- CPU Test: $((cpu_samples - 1)) amostras coletadas"
        fi
        if [ -f "$SCRIPT_DIR/io_test_$phase.tmp" ]; then
            local io_samples=$(wc -l < "$SCRIPT_DIR/io_test_$phase.tmp")
            echo "- I/O Test: $((io_samples - 1)) amostras coletadas"
        fi
        echo ""
        
        pause
    else
        echo -e "${YELLOW}Testes cancelados pelo usuario.${NC}"
        return 1
    fi
}

# Função para gerar relatório simples
generate_simple_report() {
    echo -e "${BLUE}RELATORIO DE COMPARACAO${NC}"
    echo "========================================"
    echo ""
    
    local report_file="$SCRIPT_DIR/relatorio_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "RELATORIO DE COMPARACAO DE PERFORMANCE"
        echo "======================================"
        echo "Data: $(date)"
        echo "Configuracoes:"
        echo "- Duracao dos testes: $TEST_DURATION segundos"
        echo "- Intervalo de coleta: $SAMPLE_INTERVAL segundos"
        echo "- CPU Workers: $CPU_WORKERS"
        echo ""
    } > "$report_file"
    
    # Verificar arquivos de teste
    if [ -f "$SCRIPT_DIR/cpu_test_antes.tmp" ] && [ -f "$SCRIPT_DIR/cpu_test_depois.tmp" ]; then
        echo -e "${CYAN}Comparando resultados de CPU...${NC}"
        
        # Calcular médias simples
        local antes_avg=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) printf "%.2f", sum/count}' "$SCRIPT_DIR/cpu_test_antes.tmp")
        local depois_avg=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) printf "%.2f", sum/count}' "$SCRIPT_DIR/cpu_test_depois.tmp")
        
        echo "TESTE DE CPU:"
        echo "Load Average 1min - ANTES: $antes_avg"
        echo "Load Average 1min - DEPOIS: $depois_avg"
        
        if [ -n "$antes_avg" ] && [ -n "$depois_avg" ]; then
            local improvement=$(echo "scale=1; (($antes_avg - $depois_avg) / $antes_avg) * 100" | bc -l 2>/dev/null || echo "N/A")
            echo "Melhoria: $improvement%"
        fi
        echo ""
        
        {
            echo "TESTE DE CPU:"
            echo "Load Average 1min - ANTES: $antes_avg"
            echo "Load Average 1min - DEPOIS: $depois_avg"
            echo "Melhoria: $improvement%"
            echo ""
        } >> "$report_file"
    else
        echo -e "${YELLOW}Dados de CPU incompletos. Execute os testes antes e depois.${NC}"
    fi
    
    # Verificar I/O
    if [ -f "$SCRIPT_DIR/io_test_antes.tmp" ] && [ -f "$SCRIPT_DIR/io_test_depois.tmp" ]; then
        echo -e "${CYAN}Comparando resultados de I/O...${NC}"
        
        local antes_io=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) printf "%.2f", sum/count}' "$SCRIPT_DIR/io_test_antes.tmp")
        local depois_io=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) printf "%.2f", sum/count}' "$SCRIPT_DIR/io_test_depois.tmp")
        
        echo "TESTE DE I/O:"
        echo "Load Average 1min - ANTES: $antes_io"
        echo "Load Average 1min - DEPOIS: $depois_io"
        
        if [ -n "$antes_io" ] && [ -n "$depois_io" ]; then
            local improvement_io=$(echo "scale=1; (($antes_io - $depois_io) / $antes_io) * 100" | bc -l 2>/dev/null || echo "N/A")
            echo "Melhoria: $improvement_io%"
        fi
        echo ""
        
        {
            echo "TESTE DE I/O:"
            echo "Load Average 1min - ANTES: $antes_io"
            echo "Load Average 1min - DEPOIS: $depois_io"
            echo "Melhoria: $improvement_io%"
            echo ""
        } >> "$report_file"
    fi
    
    echo -e "${GREEN}Relatorio salvo em: $report_file${NC}"
    echo ""
    pause
}

# Menu principal simplificado
show_main_menu() {
    while true; do
        show_banner
        
        echo -e "${CYAN}MENU PRINCIPAL${NC}"
        echo "========================================"
        echo ""
        echo "1) Ver informacoes do sistema"
        echo "2) Ver configuracoes dos testes"
        echo "3) Executar testes ANTES da atualizacao"
        echo "4) Executar testes DEPOIS da atualizacao"
        echo "5) Gerar relatorio comparativo"
        echo "6) Limpar dados anteriores"
        echo "7) Sair"
        echo ""
        echo -e "${YELLOW}Escolha uma opcao (1-7): ${NC}"
        
        read -r choice
        
        case "$choice" in
            1)
                clear
                show_system_info
                ;;
            2)
                clear
                show_config
                pause
                ;;
            3)
                clear
                run_test_battery "antes"
                ;;
            4)
                clear
                run_test_battery "depois"
                ;;
            5)
                clear
                generate_simple_report
                ;;
            6)
                clear
                if confirm_action "Tem certeza que deseja limpar todos os dados?"; then
                    rm -rf "$SCRIPT_DIR"
                    setup_environment
                    echo -e "${GREEN}Dados limpos!${NC}"
                else
                    echo -e "${YELLOW}Operacao cancelada.${NC}"
                fi
                pause
                ;;
            7)
                echo -e "${GREEN}Obrigado por usar o Comparador!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opcao invalida. Tente novamente.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Função principal
main() {
    setup_environment
    check_dependencies
    show_main_menu
}

# Executar
main "$@"
