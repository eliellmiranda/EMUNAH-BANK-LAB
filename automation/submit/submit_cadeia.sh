#!/bin/bash
# ================================================================
# SCRIPT  : submit_cadeia.sh
# FUNCAO  : Submeter a cadeia batch completa via Zowe CLI
#
# O QUE ESTE SCRIPT FAZ:
# - Submete cada JCL na ordem da grade batch
# - Aguarda a conclusao de cada job antes de submeter o proximo
# - Verifica o RC de cada job e para em caso de erro critico
# - Exibe resumo final com status de cada step
#
# PARA QUE ELE SERVE:
# - Automatizar a execucao da cadeia batch a partir do desktop
# - Simular um scheduler de producao usando Zowe CLI
# - Facilitar testes repetitivos do ciclo completo
#
# DEPENDENCIAS:
# - Zowe CLI instalado e configurado com perfil z/OSMF
# - Datasets do laboratorio alocados no mainframe
#
# USO: bash submit_cadeia.sh
# ================================================================

HLQ="Z77948.EMUNAH"
JCLLIB="${HLQ}.DEV.JCL"

# Cadeia na ordem de execucao
JOBS=(EBJPRECK EBJBACKP EBJLOAD EBJVALD EBJPOST EBJSALD EBJEXTR EBJCONC EBJEOD)

echo "================================================="
echo " EMUNAH BANK LAB - SUBMISSAO DA CADEIA BATCH"
echo "================================================="
echo ""

TOTAL_OK=0
TOTAL_WARN=0
TOTAL_ERRO=0

for i in "${!JOBS[@]}"; do
    JOB="${JOBS[$i]}"
    STEP=$((i + 1))
    TOTAL=${#JOBS[@]}

    echo "STEP ${STEP}/${TOTAL}: Submetendo ${JOB}..."

    # Submete o job e captura o jobid
    RESULT=$(zowe jobs submit ds "${JCLLIB}(${JOB})" --rff jobid --rft string 2>&1)

    if [ $? -ne 0 ]; then
        echo "  *** ERRO ao submeter ${JOB}: ${RESULT}"
        TOTAL_ERRO=$((TOTAL_ERRO + 1))
        echo "  Cadeia interrompida."
        break
    fi

    JOBID="${RESULT}"
    echo "  Job submetido: ${JOBID}"

    # Aguarda conclusao
    echo "  Aguardando conclusao..."
    STATUS=$(zowe jobs view job-status-by-jobid "${JOBID}" --rff retcode --rft string 2>&1)

    # Tenta aguardar por polling simples
    TENTATIVAS=0
    MAX_TENTATIVAS=30
    while [ "${STATUS}" = "null" ] || [ "${STATUS}" = "" ] && [ ${TENTATIVAS} -lt ${MAX_TENTATIVAS} ]; do
        sleep 5
        STATUS=$(zowe jobs view job-status-by-jobid "${JOBID}" --rff retcode --rft string 2>&1)
        TENTATIVAS=$((TENTATIVAS + 1))
    done

    echo "  Resultado: ${STATUS}"

    # Avalia RC
    RC_NUM=$(echo "${STATUS}" | grep -o '[0-9]*' | head -1)
    if [ -z "${RC_NUM}" ]; then
        echo "  *** Nao foi possivel determinar o RC."
        TOTAL_ERRO=$((TOTAL_ERRO + 1))
        break
    elif [ "${RC_NUM}" -gt 4 ]; then
        echo "  *** ERRO CRITICO (RC=${RC_NUM}). Cadeia interrompida."
        TOTAL_ERRO=$((TOTAL_ERRO + 1))
        break
    elif [ "${RC_NUM}" -gt 0 ]; then
        echo "  Concluido com avisos."
        TOTAL_WARN=$((TOTAL_WARN + 1))
    else
        echo "  Concluido com sucesso."
        TOTAL_OK=$((TOTAL_OK + 1))
    fi

    echo ""
done

echo "================================================="
echo " RESUMO DA CADEIA"
echo "================================================="
echo "  Jobs com sucesso : ${TOTAL_OK}"
echo "  Jobs com avisos  : ${TOTAL_WARN}"
echo "  Jobs com erro    : ${TOTAL_ERRO}"
echo "================================================="

if [ ${TOTAL_ERRO} -gt 0 ]; then
    exit 8
elif [ ${TOTAL_WARN} -gt 0 ]; then
    exit 4
else
    exit 0
fi
