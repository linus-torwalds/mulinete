#!/bin/bash

# ==============================================================================
# MULINETI RAPÁ! - Orquestrador (Wrapper) Principal
# ==============================================================================
# Este script é a porta de entrada. Ele detecta onde você está, prepara um 
# ambiente isolado (temporário) e chama o motor de testes oficial.
# A Norminette agora é avaliada silenciosamente dentro do test.sh por exercício.
# ==============================================================================

# ─── CONFIGURAÇÃO DE AMBIENTE ─────────────────────────────────────────────────

# Pega o diretório exato onde este script (.sh) está armazenado
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Tenta carregar as configurações visuais e globais
CONFIG_FILE="$SCRIPT_DIR/mini-moul/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    # Fallback básico caso o config.sh não seja encontrado
    RED=$'\033[38;5;197m'
    DEFAULT=$'\033[0m'
    echo -e "${RED}Erro Crítico: Arquivo config.sh não encontrado em ${CONFIG_FILE}${DEFAULT}"
    exit 1
fi

# Variáveis Globais de Estado
ASSIGNMENT_NAME=""
TMP_DIR="./mini-moul_tmp"

# Ícones para interface
ICON_SEARCH="🔍"
ICON_CLEAN="🧹"
ICON_ALERT="🚨"
ICON_RUN="🚀"

# ─── FUNÇÕES DE LIMPEZA E SEGURANÇA ───────────────────────────────────────────

# Remove a pasta temporária de testes para não sujar o repositório do usuário
cleanup() {
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}

# Captura o CTRL+C (SIGINT) para garantir que a pasta temporária seja apagada
# mesmo se o usuário abortar o teste no meio do caminho
handle_sigint() {
    printf "\n${RED}${ICON_ALERT} Teste abortado pelo usuário!${DEFAULT}\n"
    printf "${GREY}${ICON_CLEAN} Limpando arquivos temporários...${DEFAULT}\n"
    cleanup
    printf "${GREEN}Ambiente limpo. Falou, valeu! 🤙${DEFAULT}\n"
    exit 1
}

# ─── FUNÇÕES DE VALIDAÇÃO E PREPARAÇÃO ────────────────────────────────────────

# Identifica qual módulo o usuário está tentando testar baseado na pasta atual
detect_assignment() {
    ASSIGNMENT_NAME=$(basename "$(pwd)")
    
    # Regex rigoroso: Aceita apenas pastas válidas da Piscine (C, Shell ou Rush)
    if [[ $ASSIGNMENT_NAME =~ ^(C(0[0-9]|1[0-3])|Shell0[0-9]|Rush0[0-2])$ ]]; then
        return 0 # Sucesso
    else
        return 1 # Falha
    fi
}

# ─── FLUXO PRINCIPAL ──────────────────────────────────────────────────────────

main() {
    # 1. Valida se o usuário está na pasta certa
    if ! detect_assignment; then
        printf "${RED}${ICON_ALERT} Diretório atual (%s) não é um exercício válido.${DEFAULT}\n" "$ASSIGNMENT_NAME"
        printf "${GREY}Por favor, navegue até a pasta do módulo (ex: ${PURPLE}cd C01${GREY}) antes de rodar.${DEFAULT}\n"
        exit 1
    fi

    # 2. Registra o gatilho de segurança (CTRL+C)
    trap handle_sigint SIGINT

    # 3. Prepara o ambiente sandbox (área isolada para não conflitar com seus arquivos)
    # Copia silenciosamente a pasta do motor para dentro do exercício atual
    cp -R "$SCRIPT_DIR/mini-moul" "$TMP_DIR"

    # 4. Entra no sandbox e aciona o Motor de Testes
    cd "$TMP_DIR" || exit 1
    
    # Chama o script test.sh passando o nome do módulo (ex: "C01")
    bash ./test.sh "$ASSIGNMENT_NAME"
    
    # 5. Volta para a pasta do exercício e faz a limpeza
    cd .. || exit 1
    cleanup
}

# Inicia o script chamando a função principal
main