#!/bin/bash

# =====================================================================
# Script de Deploy de Views - Projeto Cloud MD
# Banco: PostgreSQL (Schema Perseus)
# =====================================================================

# 1. Configurações de Conexão (Ajuste conforme seu ambiente)
DB_HOST=localhost
DB_PORT=5432
DB_USER=perseus_admin
DB_NAME=perseus_dev
# Exporte a senha no seu terminal antes de rodar para não pedir a cada arquivo:
# export PGPASSWORD="sua_senha"

# 2. Prepara o diretório de logs
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
echo "Diretório de logs criado/verificado: $LOG_DIR/"
echo "---------------------------------------------------"

# Cores para o output no terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 3. Função para executar a view e capturar o log
executar_view() {
    local arquivo_sql=$1
    local wave_info=$2
    local log_file="${LOG_DIR}/${arquivo_sql}.log"

    echo -n "Executando [$wave_info] $arquivo_sql ... "

    # O flag -v ON_ERROR_STOP=1 garante que o psql retorne erro se o script falhar
    # Redirecionamos stdout (1) e stderr (2) para o arquivo de log
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
         -v ON_ERROR_STOP=1 \
         -f "$arquivo_sql" > "$log_file" 2>&1

    # Verifica o código de saída do comando anterior
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SUCESSO${NC}"
    else
        echo -e "${RED}FALHA${NC} (Veja detalhes em $log_file)"
    fi
}

# =====================================================================
# ORDEM DE EXECUÇÃO (Baseado no MIGRATION-SEQUENCE.md)
# =====================================================================

echo "Iniciando processo de migração das views..."

# WAVE 0: Views Base
WAVE0=(
    "translated.sql"
    "vw_process_upstream.sql"
    "vw_material_transition_material_up.sql"
    "vw_lot.sql"
    "vw_processable_logs.sql"
    "combined_sp_field_map.sql"
    "combined_sp_field_map_display_type.sql"
    "combined_field_map_block.sql"
)
for view in "${WAVE0[@]}"; do executar_view "$view" "WAVE 0"; done

echo -e "${YELLOW}Atenção: As próximas views da Wave 0 dependem do FDW hermes.run${NC}"
WAVE0_FDW=(
    "goo_relationship.sql"
    "hermes_run.sql"
)
for view in "${WAVE0_FDW[@]}"; do executar_view "$view" "WAVE 0 - FDW"; done

# WAVE 1: Dependentes da Wave 0
WAVE1=(
    "upstream.sql"
    "downstream.sql"
    "material_transition_material.sql"
    "vw_fermentation_upstream.sql"
    "vw_lot_edge.sql"
    "vw_lot_path.sql"
    "vw_recipe_prep.sql"
    "combined_field_map.sql"
    "combined_field_map_display_type.sql"
    "vw_tom_perseus_sample_prep_materials.sql"
)
for view in "${WAVE1[@]}"; do executar_view "$view" "WAVE 1"; done

echo -e "${YELLOW}Atenção: A view abaixo depende do FDW hermes.* e goo_relationship${NC}"
executar_view "vw_jeremy_runs.sql" "WAVE 1 - FDW"

# WAVE 2: Dependentes da Wave 1
WAVE2=(
    "vw_recipe_prep_part.sql"
)
for view in "${WAVE2[@]}"; do executar_view "$view" "WAVE 2"; done

echo "---------------------------------------------------"
echo "Processo finalizado! Revise a pasta '$LOG_DIR/' para auditar os resultados."