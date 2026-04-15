#!/bin/bash
# ================================================================
# SCRIPT  : coleta_spool.sh
# FUNCAO  : Coletar saida do spool de jobs do laboratorio
#
# O QUE ESTE SCRIPT FAZ:
# - Lista os jobs recentes do prefixo EMUNAH
# - Coleta o spool de cada job encontrado
# - Salva em arquivos locais organizados por data
# - Gera indice dos arquivos coletados
#
# PARA QUE ELE SERVE:
# - Coletar evidencias de execucao da cadeia batch
# - Montar portfolio de troubleshooting
# - Facilitar analise pos-execucao
#
# USO: bash coleta_spool.sh [prefixo-job]
# ================================================================

PREFIX="${1:-EBJ}"
DATA=$(date +%Y%m%d_%H%M%S)
DIR_SAIDA="../../data/backup/spool_${DATA}"

echo "================================================="
echo " EMUNAH BANK LAB - COLETA DE SPOOL"
echo "================================================="
echo ""
echo "Prefixo de job : ${PREFIX}*"
echo "Diretorio saida: ${DIR_SAIDA}"
echo ""

mkdir -p "${DIR_SAIDA}"

# Lista jobs com o prefixo
echo "Listando jobs..."
JOBS=$(zowe jobs list jobs --prefix "${PREFIX}*" --owner "*" --rff jobid --rft string 2>&1)

if [ $? -ne 0 ]; then
    echo "ERRO ao listar jobs: ${JOBS}"
    exit 8
fi

TOTAL=0
while IFS= read -r JOBID; do
    if [ -z "${JOBID}" ]; then
        continue
    fi

    echo "Coletando spool de ${JOBID}..."

    # Obtem nome do job
    JOBNAME=$(zowe jobs view job-status-by-jobid "${JOBID}" --rff jobname --rft string 2>&1)

    # Coleta todos os spool files
    ARQUIVO="${DIR_SAIDA}/${JOBNAME}_${JOBID}.txt"
    zowe jobs view all-spool-content "${JOBID}" > "${ARQUIVO}" 2>&1

    if [ $? -eq 0 ]; then
        echo "  Salvo em ${ARQUIVO}"
        TOTAL=$((TOTAL + 1))
    else
        echo "  ERRO ao coletar ${JOBID}"
    fi

done <<< "${JOBS}"

# Gera indice
INDICE="${DIR_SAIDA}/INDICE.txt"
echo "=================================================" > "${INDICE}"
echo " COLETA DE SPOOL - ${DATA}" >> "${INDICE}"
echo "=================================================" >> "${INDICE}"
echo "" >> "${INDICE}"
ls -la "${DIR_SAIDA}"/*.txt >> "${INDICE}" 2>/dev/null
echo "" >> "${INDICE}"
echo "Total de jobs coletados: ${TOTAL}" >> "${INDICE}"

echo ""
echo "-------------------------------------------------"
echo "Coleta concluida. ${TOTAL} job(s) coletado(s)."
echo "Saida em: ${DIR_SAIDA}"
echo "-------------------------------------------------"
