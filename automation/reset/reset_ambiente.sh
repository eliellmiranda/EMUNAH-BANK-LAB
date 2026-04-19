#!/bin/bash
# ================================================================
# SCRIPT  : reset_ambiente.sh
# FUNCAO  : Resetar o ambiente do laboratorio para estado inicial
#
# O QUE ESTE SCRIPT FAZ:
# - Deleta datasets de saida e temporarios via Zowe
# - Preserva datasets de desenvolvimento e seed
# - Preserva VSAM masters (clientes e contas)
# - Exibe resumo das operacoes realizadas
#
# PARA QUE ELE SERVE:
# - Preparar o ambiente para nova execucao da cadeia batch
# - Limpar resultados anteriores sem perder o cadastro master
# - Permitir testes repetitivos e controlados
#
# USO: bash reset_ambiente.sh [--force]
# ================================================================

HLQ="Z77948.EMUNAH"
FORCE="${1}"

echo "================================================="
echo " EMUNAH BANK LAB - RESET DO AMBIENTE"
echo "================================================="
echo ""

if [ "${FORCE}" != "--force" ]; then
    echo "ATENCAO: Este script vai deletar datasets de saida."
    echo "Datasets master e de seed serao preservados."
    echo ""
    read -p "Confirma reset? (s/N): " CONFIRMA
    if [ "${CONFIRMA}" != "s" ] && [ "${CONFIRMA}" != "S" ]; then
        echo "Reset cancelado."
        exit 0
    fi
fi

# Datasets a deletar
DATASETS=(
    "${HLQ}.ARQ.LANCTO.ESDS"
    "${HLQ}.ARQ.REJEITO.SEQ"
    "${HLQ}.ARQ.AUDIT.SEQ"
    "${HLQ}.ARQ.SALDO.OUT.SEQ"
    "${HLQ}.ARQ.CONCIL.SEQ"
    "${HLQ}.ARQ.EXTRATO.SEQ"
    "${HLQ}.ARQ.FECHTO.SEQ"
    "${HLQ}.ARQ.REPR.LANCTO.SEQ"
    "${HLQ}.ARQ.REPR.REJPERM.SEQ"
    "${HLQ}.BKP.CLIENTE.SEQ"
    "${HLQ}.BKP.CONTA.SEQ"
    "${HLQ}.BKP.AUDIT.SEQ"
)

DELETADOS=0
AUSENTES=0
ERROS=0

echo ""
for DSN in "${DATASETS[@]}"; do
    RESULT=$(zowe files list ds "${DSN}" 2>&1)
    if [ $? -eq 0 ]; then
        zowe files delete ds "${DSN}" -f 2>&1 > /dev/null
        if [ $? -eq 0 ]; then
            echo "  DELETADO - ${DSN}"
            DELETADOS=$((DELETADOS + 1))
        else
            echo "  ERRO     - ${DSN}"
            ERROS=$((ERROS + 1))
        fi
    else
        echo "  AUSENTE  - ${DSN} (nada a fazer)"
        AUSENTES=$((AUSENTES + 1))
    fi
done

echo ""
echo "-------------------------------------------------"
echo "  Datasets deletados : ${DELETADOS}"
echo "  Ja ausentes        : ${AUSENTES}"
echo "  Erros              : ${ERROS}"
echo "-------------------------------------------------"
echo ""

if [ ${ERROS} -eq 0 ]; then
    echo "Ambiente resetado com sucesso."
    echo "Execute a cadeia: bash ../submit/submit_cadeia.sh"
    exit 0
else
    echo "Reset com erros. Verifique manualmente."
    exit 8
fi
