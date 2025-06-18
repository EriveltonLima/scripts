#!/bin/bash

# Script para Gerenciar APIs do LiteLLM
# Versão 2.3 - Com Visualização Corrigida de API Keys

# Cores e estilos
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# Arquivos de configuração
CONFIG_DIR="$HOME/.litellm_manager"
APIS_FILE="$CONFIG_DIR/apis.json"
CONFIG_FILE="$CONFIG_DIR/litellm_config.yaml"
BACKUP_DIR="$CONFIG_DIR/backups"
EXPORT_DIR="$CONFIG_DIR/exports"

# Criar estrutura de diretórios
mkdir -p "$CONFIG_DIR" "$BACKUP_DIR" "$EXPORT_DIR"

# Função para mostrar header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}                    🤖 GERENCIADOR DE APIs LITELLM                    ${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}                   Organize suas chaves de API facilmente                   ${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Função para inicializar arquivo de APIs com suas APIs favoritas
init_apis_file() {
    if [[ ! -f "$APIS_FILE" ]]; then
        cat > "$APIS_FILE" << 'EOF'
{
  "apis": {
    "openai": {
      "name": "OpenAI",
      "api_key": "",
      "base_url": "https://api.openai.com/v1",
      "models": ["gpt-4", "gpt-4-turbo", "gpt-3.5-turbo", "gpt-4o"],
      "enabled": false,
      "notes": "API oficial da OpenAI"
    },
    "anthropic": {
      "name": "Anthropic (Claude)",
      "api_key": "",
      "base_url": "https://api.anthropic.com",
      "models": ["claude-3-opus", "claude-3-sonnet", "claude-3-haiku", "claude-3-5-sonnet"],
      "enabled": false,
      "notes": "API da Anthropic para Claude"
    },
    "google": {
      "name": "Google AI (Gemini)",
      "api_key": "",
      "base_url": "https://generativelanguage.googleapis.com/v1beta",
      "models": ["gemini-pro", "gemini-pro-vision", "gemini-1.5-pro", "gemini-1.5-flash"],
      "enabled": false,
      "notes": "Google Gemini API"
    },
    "grok": {
      "name": "Grok (xAI)",
      "api_key": "",
      "base_url": "https://api.x.ai/v1",
      "models": ["grok-beta", "grok-vision-beta"],
      "enabled": false,
      "notes": "API do Grok da xAI"
    },
    "mistral": {
      "name": "Mistral AI",
      "api_key": "",
      "base_url": "https://api.mistral.ai/v1",
      "models": ["mistral-large", "mistral-medium", "mistral-small", "codestral"],
      "enabled": false,
      "notes": "API da Mistral AI"
    },
    "groq": {
      "name": "Groq",
      "api_key": "",
      "base_url": "https://api.groq.com/openai/v1",
      "models": ["llama2-70b-4096", "mixtral-8x7b-32768", "gemma-7b-it"],
      "enabled": false,
      "notes": "API da Groq - Inferência rápida"
    },
    "openrouter": {
      "name": "OpenRouter",
      "api_key": "",
      "base_url": "https://openrouter.ai/api/v1",
      "models": ["openai/gpt-4", "anthropic/claude-3-opus", "google/gemini-pro", "meta-llama/llama-2-70b-chat"],
      "enabled": false,
      "notes": "OpenRouter - Acesso a múltiplos modelos"
    },
    "deepseek": {
      "name": "DeepSeek",
      "api_key": "",
      "base_url": "https://api.deepseek.com/v1",
      "models": ["deepseek-chat", "deepseek-coder"],
      "enabled": false,
      "notes": "API da DeepSeek"
    },
    "qwen": {
      "name": "Qwen (Alibaba)",
      "api_key": "",
      "base_url": "https://dashscope.aliyuncs.com/api/v1",
      "models": ["qwen-turbo", "qwen-plus", "qwen-max"],
      "enabled": false,
      "notes": "API do Qwen da Alibaba"
    }
  }
}
EOF
        echo -e "${GREEN}✅ Arquivo de APIs inicializado com suas APIs favoritas${NC}"
    fi
}

# Função para listar APIs
list_apis() {
    echo -e "${BLUE}📋 APIs Configuradas:${NC}"
    echo ""
    
    if [[ ! -f "$APIS_FILE" ]]; then
        echo -e "${YELLOW}⚠️ Nenhuma API configurada ainda${NC}"
        return
    fi
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Serviço${NC}           ${WHITE}Status${NC}    ${WHITE}Modelos Disponíveis${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    
    # Usar jq para processar JSON se disponível
    if command -v jq &> /dev/null; then
        # Comando jq corrigido
        jq -r '.apis | to_entries[] | [.key, .value.name, .value.enabled, (.value.models | join(", "))] | @tsv' "$APIS_FILE" 2>/dev/null | while IFS=$'\t' read -r key name enabled models; do
            if [[ "$enabled" == "true" ]]; then
                status="${GREEN}✅ Ativo${NC}"
            else
                status="${RED}❌ Inativo${NC}"
            fi
            printf "${CYAN}│${NC} %-15s %b  %s\n" "$name" "$status" "$models"
        done
    else
        echo -e "${CYAN}│${NC} ${YELLOW}Instale 'jq' para visualização completa: sudo apt install jq${NC}"
    fi
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Função para mostrar informações detalhadas do serviço
show_service_info() {
    local service_key="$1"
    
    echo -e "${CYAN}┌─ Informações do Serviço ─────────────────────────────────────────────────┐${NC}"
    
    case $service_key in
        "openai")
            echo -e "${CYAN}│${NC} ${WHITE}🤖 OpenAI${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}📍 URL: https://api.openai.com/v1${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}🤖 Modelos: GPT-4, GPT-4-turbo, GPT-3.5-turbo, GPT-4o${NC}"
            echo -e "${CYAN}│${NC} ${YELLOW}💡 Dica: Use chaves que começam com 'sk-'${NC}"
            ;;
        "anthropic")
            echo -e "${CYAN}│${NC} ${WHITE}🧠 Anthropic (Claude)${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}📍 URL: https://api.anthropic.com${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}🤖 Modelos: Claude-3-opus, Claude-3-sonnet, Claude-3-haiku${NC}"
            echo -e "${CYAN}│${NC} ${YELLOW}💡 Dica: Use chaves que começam com 'sk-ant-'${NC}"
            ;;
        "google")
            echo -e "${CYAN}│${NC} ${WHITE}🔍 Google AI (Gemini)${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}📍 URL: https://generativelanguage.googleapis.com/v1beta${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}🤖 Modelos: Gemini-pro, Gemini-pro-vision, Gemini-1.5${NC}"
            echo -e "${CYAN}│${NC} ${YELLOW}💡 Dica: Obtenha a chave no Google AI Studio${NC}"
            ;;
        "grok")
            echo -e "${CYAN}│${NC} ${WHITE}🚀 Grok (xAI)${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}📍 URL: https://api.x.ai/v1${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}🤖 Modelos: Grok-beta, Grok-vision-beta${NC}"
            echo -e "${CYAN}│${NC} ${YELLOW}💡 Dica: API da xAI de Elon Musk${NC}"
            ;;
        "mistral")
            echo -e "${CYAN}│${NC} ${WHITE}🎭 Mistral AI${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}📍 URL: https://api.mistral.ai/v1${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}🤖 Modelos: Mistral-large, Mistral-medium, Codestral${NC}"
            echo -e "${CYAN}│${NC} ${YELLOW}💡 Dica: Excelente para código e tarefas técnicas${NC}"
            ;;
        "groq")
            echo -e "${CYAN}│${NC} ${WHITE}⚡ Groq${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}📍 URL: https://api.groq.com/openai/v1${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}🤖 Modelos: Llama2-70b, Mixtral-8x7b, Gemma-7b${NC}"
            echo -e "${CYAN}│${NC} ${YELLOW}💡 Dica: Inferência ultra-rápida${NC}"
            ;;
        "openrouter")
            echo -e "${CYAN}│${NC} ${WHITE}🌐 OpenRouter${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}📍 URL: https://openrouter.ai/api/v1${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}🤖 Modelos: Acesso a múltiplos provedores${NC}"
            echo -e "${CYAN}│${NC} ${YELLOW}💡 Dica: Chaves começam com 'sk-or-v1-'${NC}"
            ;;
        "deepseek")
            echo -e "${CYAN}│${NC} ${WHITE}🔬 DeepSeek${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}📍 URL: https://api.deepseek.com/v1${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}🤖 Modelos: DeepSeek-chat, DeepSeek-coder${NC}"
            echo -e "${CYAN}│${NC} ${YELLOW}💡 Dica: Especializado em programação${NC}"
            ;;
        "qwen")
            echo -e "${CYAN}│${NC} ${WHITE}🏮 Qwen (Alibaba)${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}📍 URL: https://dashscope.aliyuncs.com/api/v1${NC}"
            echo -e "${CYAN}│${NC} ${BLUE}🤖 Modelos: Qwen-turbo, Qwen-plus, Qwen-max${NC}"
            echo -e "${CYAN}│${NC} ${YELLOW}💡 Dica: Modelo chinês da Alibaba${NC}"
            ;;
    esac
    
    echo -e "${CYAN}└───────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Função para adicionar/editar API com seleção numérica
manage_api() {
    local service_key="$1"
    
    if [[ -z "$service_key" ]]; then
        echo ""
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC} ${WHITE}                        🎯 SELECIONAR SERVIÇO                        ${NC} ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}Serviços disponíveis:${NC}"
        echo ""
        echo -e "${WHITE}[1]${NC}  🤖 OpenAI - GPT-4, GPT-3.5-turbo, GPT-4o"
        echo -e "${WHITE}[2]${NC}  🧠 Anthropic - Claude 3 (Opus, Sonnet, Haiku)"
        echo -e "${WHITE}[3]${NC}  🔍 Google AI - Gemini Pro, Gemini 1.5"
        echo -e "${WHITE}[4]${NC}  🚀 Grok (xAI) - Grok Beta, Grok Vision"
        echo -e "${WHITE}[5]${NC}  🎭 Mistral AI - Large, Medium, Small, Codestral"
        echo -e "${WHITE}[6]${NC}  ⚡ Groq - Llama2, Mixtral, Gemma (Inferência rápida)"
        echo -e "${WHITE}[7]${NC}  🌐 OpenRouter - Acesso a múltiplos modelos"
        echo -e "${WHITE}[8]${NC}  🔬 DeepSeek - Chat e Coder"
        echo -e "${WHITE}[9]${NC}  🏮 Qwen (Alibaba) - Turbo, Plus, Max"
        echo -e "${WHITE}[10]${NC} 🛠️  Serviço personalizado"
        echo ""
        
        while true; do
            read -p "$(echo -e ${GREEN}🎯${NC}) Selecione o serviço [1-10]: " service_choice
            
            case $service_choice in
                1)
                    service_key="openai"
                    echo -e "${BLUE}✅ Selecionado: OpenAI${NC}"
                    break
                    ;;
                2)
                    service_key="anthropic"
                    echo -e "${BLUE}✅ Selecionado: Anthropic (Claude)${NC}"
                    break
                    ;;
                3)
                    service_key="google"
                    echo -e "${BLUE}✅ Selecionado: Google AI (Gemini)${NC}"
                    break
                    ;;
                4)
                    service_key="grok"
                    echo -e "${BLUE}✅ Selecionado: Grok (xAI)${NC}"
                    break
                    ;;
                5)
                    service_key="mistral"
                    echo -e "${BLUE}✅ Selecionado: Mistral AI${NC}"
                    break
                    ;;
                6)
                    service_key="groq"
                    echo -e "${BLUE}✅ Selecionado: Groq${NC}"
                    break
                    ;;
                7)
                    service_key="openrouter"
                    echo -e "${BLUE}✅ Selecionado: OpenRouter${NC}"
                    break
                    ;;
                8)
                    service_key="deepseek"
                    echo -e "${BLUE}✅ Selecionado: DeepSeek${NC}"
                    break
                    ;;
                9)
                    service_key="qwen"
                    echo -e "${BLUE}✅ Selecionado: Qwen (Alibaba)${NC}"
                    break
                    ;;
                10)
                    echo -e "${BLUE}✅ Selecionado: Serviço personalizado${NC}"
                    add_custom_api
                    return
                    ;;
                *)
                    echo -e "${RED}❌ Opção inválida! Digite um número de 1 a 10.${NC}"
                    ;;
            esac
        done
    fi
    
    echo ""
    echo -e "${BLUE}🔧 Configurando: $service_key${NC}"
    echo ""
    
    # Obter informações atuais se existirem
    local current_key=""
    local current_base_url=""
    local current_notes=""
    
    if command -v jq &> /dev/null && [[ -f "$APIS_FILE" ]]; then
        current_key=$(jq -r ".apis.$service_key.api_key // \"\"" "$APIS_FILE" 2>/dev/null)
        current_base_url=$(jq -r ".apis.$service_key.base_url // \"\"" "$APIS_FILE" 2>/dev/null)
        current_notes=$(jq -r ".apis.$service_key.notes // \"\"" "$APIS_FILE" 2>/dev/null)
    fi
    
    # Mostrar informações do serviço selecionado
    show_service_info "$service_key"
    
    # Coletar nova API key
    echo -e "${GREEN}🔑 API Key:${NC}"
    if [[ -n "$current_key" && "$current_key" != "null" && "$current_key" != "" ]]; then
        echo -e "${GRAY}   Atual: ${current_key:0:8}...${current_key: -4}${NC}"
    fi
    echo -e "${GRAY}   (A chave não será exibida enquanto digita)${NC}"
    read -s new_api_key
    echo ""
    
    if [[ -z "$new_api_key" ]]; then
        echo -e "${RED}❌ API Key é obrigatória!${NC}"
        return
    fi
    
    # Base URL (opcional)
    echo -e "${GREEN}🌐 Base URL (opcional):${NC}"
    if [[ -n "$current_base_url" && "$current_base_url" != "null" ]]; then
        echo -e "${GRAY}   Atual: $current_base_url${NC}"
    fi
    read -p "   Nova URL (Enter para manter): " new_base_url
    
    # Notas (opcional)
    echo -e "${GREEN}📝 Notas (opcional):${NC}"
    if [[ -n "$current_notes" && "$current_notes" != "null" ]]; then
        echo -e "${GRAY}   Atual: $current_notes${NC}"
    fi
    read -p "   Novas notas: " new_notes
    
    # Ativar API
    echo ""
    read -p "$(echo -e ${GREEN}✅${NC}) Ativar esta API? [S/n]: " activate
    local enabled="true"
    if [[ "$activate" =~ ^[Nn]$ ]]; then
        enabled="false"
    fi
    
    # Atualizar arquivo JSON
    update_api_config "$service_key" "$new_api_key" "$new_base_url" "$new_notes" "$enabled"
}

# Função para atualizar configuração da API
update_api_config() {
    local service_key="$1"
    local api_key="$2"
    local base_url="$3"
    local notes="$4"
    local enabled="$5"
    
    if command -v jq &> /dev/null; then
        local temp_file=$(mktemp)
        
        # Construir comando jq dinamicamente
        local jq_cmd=".apis.$service_key.api_key = \"$api_key\" | .apis.$service_key.enabled = $enabled"
        
        if [[ -n "$base_url" ]]; then
            jq_cmd="$jq_cmd | .apis.$service_key.base_url = \"$base_url\""
        fi
        
        if [[ -n "$notes" ]]; then
            jq_cmd="$jq_cmd | .apis.$service_key.notes = \"$notes\""
        fi
        
        jq "$jq_cmd" "$APIS_FILE" > "$temp_file" && mv "$temp_file" "$APIS_FILE"
        echo -e "${GREEN}✅ API '$service_key' configurada com sucesso!${NC}"
    else
        echo -e "${RED}❌ jq não está instalado. Instale com: sudo apt install jq${NC}"
    fi
}

# Função para adicionar API personalizada
add_custom_api() {
    echo ""
    echo -e "${BLUE}🛠️ Adicionando API Personalizada${NC}"
    echo ""
    
    read -p "$(echo -e ${GREEN}📛${NC}) Nome do serviço: " custom_name
    read -p "$(echo -e ${GREEN}🔑${NC}) API Key: " -s custom_key
    echo ""
    read -p "$(echo -e ${GREEN}🌐${NC}) Base URL: " custom_url
    read -p "$(echo -e ${GREEN}🤖${NC}) Modelos (separados por vírgula): " custom_models
    read -p "$(echo -e ${GREEN}📝${NC}) Notas: " custom_notes
    
    # Gerar chave única para o serviço
    local service_key=$(echo "$custom_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
    
    # Converter modelos para array JSON
    local models_array="["
    IFS=',' read -ra MODELS <<< "$custom_models"
    for i in "${!MODELS[@]}"; do
        if [[ $i -gt 0 ]]; then
            models_array+=", "
        fi
        models_array+="\"$(echo "${MODELS[$i]}" | xargs)\""
    done
    models_array+="]"
    
    # Adicionar ao arquivo JSON
    if command -v jq &> /dev/null; then
        local temp_file=$(mktemp)
        jq ".apis.$service_key = {
            \"name\": \"$custom_name\",
            \"api_key\": \"$custom_key\",
            \"base_url\": \"$custom_url\",
            \"models\": $models_array,
            \"enabled\": true,
            \"notes\": \"$custom_notes\"
        }" "$APIS_FILE" > "$temp_file" && mv "$temp_file" "$APIS_FILE"
        
        echo -e "${GREEN}✅ API personalizada '$custom_name' adicionada!${NC}"
    else
        echo -e "${RED}❌ jq não está instalado. Instale com: sudo apt install jq${NC}"
    fi
}

# Função para mascarar chave API
mask_api_key() {
    local api_key="$1"
    if [[ ${#api_key} -gt 12 ]]; then
        echo "${api_key:0:8}...${api_key: -4}"
    elif [[ ${#api_key} -gt 6 ]]; then
        echo "${api_key:0:4}...${api_key: -2}"
    else
        echo "***...***"
    fi
}

# Função para visualizar APIs cadastradas com chaves mascaradas
view_registered_apis() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}                    📋 APIS CADASTRADAS (MASCARADAS)                    ${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -f "$APIS_FILE" ]] || ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ Arquivo de APIs não encontrado ou jq não instalado${NC}"
        echo ""
        read -p "Pressione Enter para continuar..."
        return
    fi
    
    # Comando jq corrigido usando @tsv para evitar problemas de escape
    local active_apis=$(jq -r '.apis | to_entries[] | select(.value.enabled == true) | [.key, .value.name, .value.api_key, .value.base_url, (.value.models | join(", "))] | @tsv' "$APIS_FILE" 2>/dev/null)
    
    if [[ -z "$active_apis" ]]; then
        echo -e "${YELLOW}⚠️ Nenhuma API ativa encontrada${NC}"
        echo ""
        read -p "Pressione Enter para continuar..."
        return
    fi
    
    echo -e "${GREEN}🔑 APIs Ativas (Chaves Mascaradas):${NC}"
    echo ""
    
    local count=1
    echo "$active_apis" | while IFS=$'\t' read -r key name api_key base_url models; do
        local masked_key=$(mask_api_key "$api_key")
        
        echo -e "${WHITE}[$count] $name${NC}"
        echo -e "${BLUE}    🔗 Chave: $masked_key${NC}"
        echo -e "${BLUE}    🌐 URL: $base_url${NC}"
        echo -e "${BLUE}    🤖 Modelos: $models${NC}"
        echo ""
        ((count++))
    done
    
    echo ""
    echo -e "${CYAN}Opções de Visualização e Exportação:${NC}"
    echo -e "${GREEN}[1]${NC} 👁️ Ver chaves completas (CUIDADO!)"
    echo -e "${GREEN}[2]${NC} 💾 Salvar em arquivo TXT (chaves mascaradas)"
    echo -e "${GREEN}[3]${NC} 💾 Salvar em arquivo TXT (chaves completas)"
    echo -e "${GREEN}[4]${NC} 📋 Copiar para clipboard (chaves mascaradas)"
    echo -e "${GREEN}[5]${NC} 📋 Copiar para clipboard (chaves completas)"
    echo -e "${GREEN}[6]${NC} 📄 Exportar configuração LiteLLM"
    echo -e "${GREEN}[7]${NC} ⬅️ Voltar ao menu"
    echo ""
    
    read -p "$(echo -e ${GREEN}🎯${NC}) Opção: " export_option
    
    case $export_option in
        1) view_registered_apis_full ;;
        2) export_to_txt "masked" ;;
        3) export_to_txt "full" ;;
        4) copy_to_clipboard "masked" ;;
        5) copy_to_clipboard "full" ;;
        6) export_litellm_format ;;
        7) return ;;
        *) echo -e "${RED}❌ Opção inválida!${NC}"; sleep 1; view_registered_apis ;;
    esac
}

# Função para visualizar APIs com chaves completas
view_registered_apis_full() {
    clear
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} ${WHITE}                    ⚠️ APIS CADASTRADAS (CHAVES COMPLETAS) ⚠️                    ${NC} ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}🔒 ATENÇÃO: As chaves API estão sendo exibidas completas!${NC}"
    echo -e "${YELLOW}🛡️ Certifique-se de que ninguém mais está vendo sua tela.${NC}"
    echo ""
    
    if [[ ! -f "$APIS_FILE" ]] || ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ Arquivo de APIs não encontrado ou jq não instalado${NC}"
        echo ""
        read -p "Pressione Enter para continuar..."
        return
    fi
    
    # Comando jq corrigido usando @tsv para evitar problemas de escape
    local active_apis=$(jq -r '.apis | to_entries[] | select(.value.enabled == true) | [.key, .value.name, .value.api_key, .value.base_url, (.value.models | join(", "))] | @tsv' "$APIS_FILE" 2>/dev/null)
    
    if [[ -z "$active_apis" ]]; then
        echo -e "${YELLOW}⚠️ Nenhuma API ativa encontrada${NC}"
        echo ""
        read -p "Pressione Enter para continuar..."
        return
    fi
    
    echo -e "${GREEN}🔑 APIs Ativas (Chaves Completas):${NC}"
    echo ""
    
    local count=1
    echo "$active_apis" | while IFS=$'\t' read -r key name api_key base_url models; do
        echo -e "${WHITE}[$count] $name${NC}"
        echo -e "${BLUE}    🔗 Chave: ${YELLOW}$api_key${NC}"
        echo -e "${BLUE}    🌐 URL: $base_url${NC}"
        echo -e "${BLUE}    🤖 Modelos: $models${NC}"
        echo ""
        ((count++))
    done
    
    echo ""
    echo -e "${RED}⚠️ Lembre-se de limpar o terminal após visualizar: clear${NC}"
    echo ""
    echo -e "${CYAN}Opções:${NC}"
    echo -e "${GREEN}[1]${NC} 🔒 Voltar para visualização mascarada"
    echo -e "${GREEN}[2]${NC} 🧹 Limpar tela e voltar"
    echo -e "${GREEN}[3]${NC} ⬅️ Voltar ao menu principal"
    echo ""
    
    read -p "$(echo -e ${GREEN}🎯${NC}) Opção: " option
    
    case $option in
        1) view_registered_apis ;;
        2) clear; view_registered_apis ;;
        3) clear; return ;;
        *) echo -e "${RED}❌ Opção inválida!${NC}"; sleep 1; view_registered_apis_full ;;
    esac
}

# Função para exportar para TXT
export_to_txt() {
    local mode="${1:-masked}"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local export_file="$EXPORT_DIR/apis_cadastradas_${mode}_$timestamp.txt"
    
    echo "APIS CADASTRADAS - LITELLM MANAGER" > "$export_file"
    echo "Modo: $mode" >> "$export_file"
    echo "Gerado em: $(date)" >> "$export_file"
    echo "=========================================" >> "$export_file"
    echo "" >> "$export_file"
    
    if command -v jq &> /dev/null; then
        local count=1
        # Comando jq corrigido usando @tsv
        jq -r '.apis | to_entries[] | select(.value.enabled == true) | [.key, .value.name, .value.api_key, .value.base_url, (.value.models | join(", "))] | @tsv' "$APIS_FILE" 2>/dev/null | while IFS=$'\t' read -r key name api_key base_url models; do
            echo "[$count] $name" >> "$export_file"
            
            if [[ "$mode" == "full" ]]; then
                echo "    Chave API: $api_key" >> "$export_file"
            else
                local masked_key=$(mask_api_key "$api_key")
                echo "    Chave API: $masked_key" >> "$export_file"
            fi
            
            echo "    Base URL: $base_url" >> "$export_file"
            echo "    Modelos: $models" >> "$export_file"
            echo "" >> "$export_file"
            ((count++))
        done
        
        echo "=========================================" >> "$export_file"
        echo "Total de APIs ativas: $((count-1))" >> "$export_file"
        echo "" >> "$export_file"
        echo "Arquivo gerado pelo LiteLLM Manager" >> "$export_file"
        
        if [[ "$mode" == "full" ]]; then
            echo "" >> "$export_file"
            echo "⚠️ ATENÇÃO: Este arquivo contém chaves API completas!" >> "$export_file"
            echo "🔒 Mantenha este arquivo seguro e não compartilhe." >> "$export_file"
        fi
        
        echo -e "${GREEN}✅ Arquivo exportado: $export_file${NC}"
        
        # Oferecer para abrir o arquivo
        echo ""
        read -p "$(echo -e ${BLUE}📄${NC}) Deseja abrir o arquivo? [s/N]: " open_file
        if [[ "$open_file" =~ ^[Ss]$ ]]; then
            if command -v xdg-open &> /dev/null; then
                xdg-open "$export_file"
            elif command -v gedit &> /dev/null; then
                gedit "$export_file" &
            elif command -v nano &> /dev/null; then
                nano "$export_file"
            else
                echo -e "${BLUE}📁 Arquivo salvo em: $export_file${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ jq não está instalado${NC}"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Função para copiar para clipboard
copy_to_clipboard() {
    local mode="${1:-masked}"
    local temp_file=$(mktemp)
    
    echo "APIS CADASTRADAS - LITELLM" > "$temp_file"
    echo "Modo: $mode" >> "$temp_file"
    echo "=========================" >> "$temp_file"
    echo "" >> "$temp_file"
    
    if command -v jq &> /dev/null; then
        local count=1
        # Comando jq corrigido usando @tsv
        jq -r '.apis | to_entries[] | select(.value.enabled == true) | [.key, .value.name, .value.api_key, .value.base_url] | @tsv' "$APIS_FILE" 2>/dev/null | while IFS=$'\t' read -r key name api_key base_url; do
            echo "[$count] $name" >> "$temp_file"
            
            if [[ "$mode" == "full" ]]; then
                echo "    API Key: $api_key" >> "$temp_file"
            else
                local masked_key=$(mask_api_key "$api_key")
                echo "    API Key: $masked_key" >> "$temp_file"
            fi
            
            echo "    URL: $base_url" >> "$temp_file"
            echo "" >> "$temp_file"
            ((count++))
        done
        
        # Tentar copiar para clipboard
        if command -v xclip &> /dev/null; then
            cat "$temp_file" | xclip -selection clipboard
            echo -e "${GREEN}✅ Copiado para o clipboard!${NC}"
        elif command -v pbcopy &> /dev/null; then
            cat "$temp_file" | pbcopy
            echo -e "${GREEN}✅ Copiado para o clipboard!${NC}"
        else
            echo -e "${YELLOW}⚠️ Clipboard não disponível. Conteúdo:${NC}"
            echo ""
            cat "$temp_file"
        fi
    else
        echo -e "${RED}❌ jq não está instalado${NC}"
    fi
    
    rm -f "$temp_file"
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Função para exportar no formato LiteLLM
export_litellm_format() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local export_file="$EXPORT_DIR/litellm_config_$timestamp.yaml"
    
    echo "# Configuração LiteLLM - APIs Cadastradas" > "$export_file"
    echo "# Gerado em: $(date)" >> "$export_file"
    echo "" >> "$export_file"
    echo "model_list:" >> "$export_file"
    
    if command -v jq &> /dev/null; then
        # Comando jq corrigido usando @tsv
        jq -r '.apis | to_entries[] | select(.value.enabled == true) | [.key, .value.name, .value.api_key, .value.base_url, (.value.models | join(","))] | @tsv' "$APIS_FILE" 2>/dev/null | while IFS=$'\t' read -r key name api_key base_url models; do
            IFS=',' read -ra MODEL_ARRAY <<< "$models"
            
            for model in "${MODEL_ARRAY[@]}"; do
                model=$(echo "$model" | xargs)
                echo "  - model_name: $model" >> "$export_file"
                echo "    litellm_params:" >> "$export_file"
                echo "      model: $key/$model" >> "$export_file"
                echo "      api_key: $api_key" >> "$export_file"
                if [[ -n "$base_url" && "$base_url" != "null" ]]; then
                    echo "      api_base: $base_url" >> "$export_file"
                fi
                echo "" >> "$export_file"
            done
        done
        
        echo "# Configurações gerais" >> "$export_file"
        echo "general_settings:" >> "$export_file"
        echo "  master_key: \"sk-1234\" # Altere esta chave" >> "$export_file"
        echo "  database_url: \"sqlite:///litellm.db\"" >> "$export_file"
        
        echo -e "${GREEN}✅ Configuração LiteLLM exportada: $export_file${NC}"
        echo -e "${BLUE}💡 Para usar: litellm --config $export_file${NC}"
    else
        echo -e "${RED}❌ jq não está instalado${NC}"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Função para gerar configuração do LiteLLM
generate_litellm_config() {
    echo -e "${BLUE}📄 Gerando configuração do LiteLLM...${NC}"
    
    if [[ ! -f "$APIS_FILE" ]] || ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ Arquivo de APIs não encontrado ou jq não instalado${NC}"
        return
    fi
    
    # Criar backup da configuração atual
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$BACKUP_DIR/litellm_config_$(date +%Y%m%d_%H%M%S).yaml"
    fi
    
    # Gerar nova configuração
    cat > "$CONFIG_FILE" << 'EOF'
# Configuração do LiteLLM
# Gerada automaticamente pelo Gerenciador de APIs

model_list:
EOF
    
    # Adicionar modelos ativos usando comando jq corrigido
    jq -r '.apis | to_entries[] | select(.value.enabled == true) | [.key, .value.name, .value.api_key, .value.base_url, (.value.models | join(","))] | @tsv' "$APIS_FILE" 2>/dev/null | while IFS=$'\t' read -r key name api_key base_url models; do
        IFS=',' read -ra MODEL_ARRAY <<< "$models"
        
        for model in "${MODEL_ARRAY[@]}"; do
            model=$(echo "$model" | xargs) # Trim whitespace
            cat >> "$CONFIG_FILE" << EOF
  - model_name: $model
    litellm_params:
      model: $key/$model
      api_key: $api_key
EOF
            if [[ -n "$base_url" && "$base_url" != "null" ]]; then
                echo "      api_base: $base_url" >> "$CONFIG_FILE"
            fi
            echo "" >> "$CONFIG_FILE"
        done
    done
    
    # Adicionar configurações gerais
    cat >> "$CONFIG_FILE" << 'EOF'
# Configurações gerais
general_settings:
  master_key: "sk-1234" # Altere esta chave
  database_url: "sqlite:///litellm.db"
  
# Configurações de logging
litellm_settings:
  success_callback: ["langfuse"]
  failure_callback: ["langfuse"]
  
# Rate limiting (opcional)
router_settings:
  routing_strategy: "least-busy"
  model_group_alias:
    gpt-4: ["gpt-4", "claude-3-opus"]
    gpt-3.5: ["gpt-3.5-turbo", "claude-3-haiku"]
EOF
    
    echo -e "${GREEN}✅ Configuração gerada: $CONFIG_FILE${NC}"
    echo -e "${BLUE}💡 Para usar: litellm --config $CONFIG_FILE${NC}"
}

# Função para remover API
remove_api() {
    echo ""
    list_apis
    echo ""
    read -p "$(echo -e ${RED}🗑️${NC}) Digite o nome do serviço para remover: " service_key
    
    if [[ -z "$service_key" ]]; then
        echo -e "${RED}❌ Nome do serviço é obrigatório!${NC}"
        return
    fi
    
    echo -e "${RED}⚠️ Confirma a remoção da API '$service_key'?${NC}"
    read -p "   [s/N]: " confirm
    
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        if command -v jq &> /dev/null; then
            local temp_file=$(mktemp)
            jq "del(.apis.$service_key)" "$APIS_FILE" > "$temp_file" && mv "$temp_file" "$APIS_FILE"
            echo -e "${GREEN}✅ API '$service_key' removida!${NC}"
        else
            echo -e "${RED}❌ jq não está instalado${NC}"
        fi
    else
        echo -e "${BLUE}❌ Remoção cancelada${NC}"
    fi
}

# Menu principal
main_menu() {
    while true; do
        show_header
        list_apis
        
        echo -e "${WHITE}Selecione uma opção:${NC}"
        echo ""
        echo -e "${GREEN}[1]${NC} ➕ Adicionar/Editar API"
        echo -e "${GREEN}[2]${NC} 📋 Visualizar APIs cadastradas"
        echo -e "${GREEN}[3]${NC} 📄 Gerar configuração LiteLLM"
        echo -e "${GREEN}[4]${NC} 🗑️ Remover API"
        echo -e "${GREEN}[5]${NC} 📁 Abrir pasta de configuração"
        echo -e "${GREEN}[6]${NC} ❌ Sair"
        echo ""
        
        read -p "$(echo -e ${GREEN}🎯${NC}) Opção: " option
        
        case $option in
            1)
                manage_api
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
            2)
                view_registered_apis
                ;;
            3)
                generate_litellm_config
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
            4)
                remove_api
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
            5)
                echo -e "${BLUE}📁 Pasta de configuração: $CONFIG_DIR${NC}"
                if command -v xdg-open &> /dev/null; then
                    xdg-open "$CONFIG_DIR"
                elif command -v nautilus &> /dev/null; then
                    nautilus "$CONFIG_DIR"
                else
                    echo -e "${YELLOW}💡 Abra manualmente: $CONFIG_DIR${NC}"
                fi
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
            6)
                echo -e "${GREEN}👋 Até logo!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Verificar dependências
check_dependencies() {
    local missing_deps=()
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️ Dependências faltando: ${missing_deps[*]}${NC}"
        echo -e "${BLUE}💡 Instale com: sudo apt install ${missing_deps[*]}${NC}"
        echo ""
        read -p "Continuar mesmo assim? [s/N]: " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Ss]$ ]]; then
            exit 1
        fi
    fi
}

# Inicialização
main() {
    check_dependencies
    init_apis_file
    main_menu
}

# Executar script
main
