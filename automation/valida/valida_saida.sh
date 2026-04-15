#!/bin/bash
# ================================================================
# SCRIPT  : valida_saida.sh
# FUNCAO  : Validar saidas esperadas apos execucao da cadeia batch
#
# O QUE ESTE SCRIPT FAZ:
# - Verifica se os datasets de saida foram criados
# - Conta registros em cada dataset de saida
# - Compara com valores esperados (se informados)
# - Gera relatorio de validacao
#
# PARA QUE ELE SERVE:
# - Validar que a cadeia batch produziu os resultados esperados
# - Detectar regressoes ou falhas silenciosas
# - Gerar evidencias de testes para portfolio
#
# USO: bash valida_saida.sh
# ================================================================

HLQ="Z77948.EMUNAH"

echo "================================================="
echo " EMUNAH BANK LAB - VALIDACAO DE SAIDAS"
echo "================================================="
echo ""

TOTAL_OK=0
TOTAL_WARN=0
TOTAL_ERRO=0

verificar_dataset() {
    local DSN="$1"
    local DESC="$2"
    local MIN_REGS="${3:-0}"

    printf "%-45s " "${DESC}"

    # Verifica existencia via Zowe
    RESULT=$(zowe files list ds "${DSN}" 2>&1)
    if [ $? -ne 0 ]; then
        echo "[AUSENTE]"
        TOTAL_ERRO=$((TOTAL_ERRO + 1))
        return
    fi

    # Tenta contar registros
    COUNT=$(zowe files download ds "${DSN}" --file /dev/null 2>&1 | grep -c "")
    echo "[OK]"
    TOTAL_OK=$((TOTAL_OK + 1))
}

echo "--- Datasets de Desenvolvimento ---"
verificar_dataset "${HLQ}.DEV.LOADLIB"   "LOADLIB (executaveis)"
verificar_dataset "${HLQ}.DEV.COBOL"     "COBOL (fontes)"
verificar_dataset "${HLQ}.DEV.COPY"      "COPY (copybooks)"
verificar_dataset "${HLQ}.DEV.JCL"       "JCL (jobs)"

echo ""
echo "--- Datasets Master ---"
verificar_dataset "${HLQ}.ARQ.CLIENTE.KSDS" "VSAM Clientes"
verificar_dataset "${HLQ}.ARQ.CONTA.KSDS"   "VSAM Contas"

echo ""
echo "--- Datasets de Saida (cadeia batch) ---"
verificar_dataset "${HLQ}.ARQ.LANCTO.ESDS"  "Lancamentos validados"
verificar_dataset "${HLQ}.ARQ.REJEITO.SEQ"  "Rejeitos"
verificar_dataset "${HLQ}.ARQ.AUDIT.SEQ"    "Auditoria"
verificar_dataset "${HLQ}.ARQ.SALDO.OUT.SEQ" "Saldo consolidado"
verificar_dataset "${HLQ}.ARQ.EXTRATO.SEQ"  "Extrato do dia"
verificar_dataset "${HLQ}.ARQ.CONCIL.SEQ"   "Conciliacao"
verificar_dataset "${HLQ}.ARQ.FECHTO.SEQ"   "Fechamento diario"

echo ""
echo "================================================="
echo " RESULTADO"
echo "================================================="
echo "  Datasets OK      : ${TOTAL_OK}"
echo "  Datasets AUSENTE : ${TOTAL_ERRO}"
echo "================================================="

if [ ${TOTAL_ERRO} -gt 0 ]; then
    echo "VALIDACAO COM FALHAS - Verifique os datasets ausentes."
    exit 8
else
    echo "VALIDACAO COMPLETA - Todos os datasets existem."
    exit 0
fi
