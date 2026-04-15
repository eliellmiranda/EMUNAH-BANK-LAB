#!/bin/bash
# ================================================================
# SCRIPT  : simula_incidente.sh
# FUNCAO  : Simular incidentes controlados para pratica de
#           troubleshooting no laboratorio Emunah Bank
#
# O QUE ESTE SCRIPT FAZ:
# - Recebe um codigo de cenario como parametro
# - Aplica a falha correspondente no ambiente
# - Exibe instrucoes de diagnostico para o operador
#
# PARA QUE ELE SERVE:
# - Criar cenarios controlados de falha para pratica
# - Treinar analise de problemas em ambiente seguro
# - Gerar evidencias de troubleshooting para portfolio
#
# CENARIOS DISPONIVEIS:
#   1 - Arquivo de entrada ausente
#   2 - Registro com tipo de lancamento invalido
#   3 - VSAM de contas inacessivel (rename simulado)
#   4 - Arquivo de auditoria com espaco esgotado (dummy)
#   5 - Programa EBVALI01 ausente da LOADLIB
#
# USO: bash simula_incidente.sh <numero-cenario>
# ================================================================

HLQ="Z77948.EMUNAH"
CENARIO="${1}"

echo "================================================="
echo " EMUNAH BANK LAB - SIMULACAO DE INCIDENTE"
echo "================================================="
echo ""

if [ -z "${CENARIO}" ]; then
    echo "USO: simula_incidente.sh <numero>"
    echo ""
    echo "Cenarios disponiveis:"
    echo "  1 - Arquivo de entrada ausente"
    echo "  2 - Registro com tipo invalido no lancamento"
    echo "  3 - VSAM de contas renomeado (inacessivel)"
    echo "  4 - Auditoria com espaco esgotado"
    echo "  5 - Programa ausente da LOADLIB"
    exit 4
fi

case "${CENARIO}" in
    1)
        echo "CENARIO 1: Removendo arquivo de entrada do dia"
        echo ""
        zowe files delete ds "${HLQ}.ARQ.ENTRADA.SEQ" -f 2>&1
        echo ""
        echo "Falha aplicada. O job EBJLOAD deve falhar com RC=12."
        echo ""
        echo "INSTRUCOES DE DIAGNOSTICO:"
        echo "  1. Submeta EBJLOAD e observe o RC"
        echo "  2. Verifique o spool do PRECHECK (IDCAMS)"
        echo "  3. Use LISTCAT para confirmar a ausencia"
        echo "  4. Recrie o dataset e reexecute"
        ;;
    2)
        echo "CENARIO 2: Inserindo lancamento com tipo invalido"
        echo ""
        echo "Editando o arquivo de entrada para incluir tipo 'X'..."
        # Cria um registro com tipo invalido
        echo "0001000000012025041520X000000010000LANCAMENTO INVALIDO    APP       " > /tmp/registro_invalido.txt
        zowe files upload ftu /tmp/registro_invalido.txt "${HLQ}.ARQ.ENTRADA.SEQ" 2>&1
        echo ""
        echo "Falha aplicada. O job EBJVALD deve rejeitar o registro."
        echo ""
        echo "INSTRUCOES DE DIAGNOSTICO:"
        echo "  1. Submeta EBJVALD e observe o RC (esperado: 4)"
        echo "  2. Verifique o arquivo de rejeitos"
        echo "  3. Analise o motivo da rejeicao no spool"
        echo "  4. Corrija o registro e reprocesse com EBJREPR"
        ;;
    3)
        echo "CENARIO 3: Renomeando VSAM de contas"
        echo ""
        echo "Aplicando rename no VSAM..."
        zowe files invoke ams-statements "ALTER '${HLQ}.ARQ.CONTA.KSDS' NEWNAME('${HLQ}.ARQ.CONTA.KSDS.BAK')" 2>&1
        echo ""
        echo "Falha aplicada. Jobs EBJPOST e EBJSALD devem falhar."
        echo ""
        echo "INSTRUCOES DE DIAGNOSTICO:"
        echo "  1. Submeta EBJPOST e observe o erro de OPEN"
        echo "  2. Verifique o file status no spool"
        echo "  3. Use LISTCAT para investigar o dataset"
        echo "  4. Restaure com: ALTER NEWNAME para o nome original"
        echo ""
        echo "PARA RESTAURAR:"
        echo "  zowe files invoke ams-statements \\"
        echo "    \"ALTER '${HLQ}.ARQ.CONTA.KSDS.BAK' NEWNAME('${HLQ}.ARQ.CONTA.KSDS')\""
        ;;
    4)
        echo "CENARIO 4: Simulando espaco esgotado na auditoria"
        echo ""
        echo "Para simular, realoque o dataset com espaco minimo:"
        echo "  DELETE '${HLQ}.ARQ.AUDIT.SEQ'"
        echo "  ALLOCATE DA('${HLQ}.ARQ.AUDIT.SEQ') SPACE(1 0) TRACKS"
        echo ""
        echo "Depois execute a cadeia completa. O EBPOST01 deve"
        echo "falhar ao gravar a auditoria (file status 34 ou 35)."
        echo ""
        echo "INSTRUCOES DE DIAGNOSTICO:"
        echo "  1. Observe o file status do WRITE no AUDIT-OUT"
        echo "  2. Verifique o espaco do dataset com LISTDSI"
        echo "  3. Realoque com espaco adequado"
        echo "  4. Reexecute a partir do step que falhou"
        ;;
    5)
        echo "CENARIO 5: Removendo programa da LOADLIB"
        echo ""
        echo "Renomeando EBVALI01 na LOADLIB..."
        zowe files invoke ams-statements "ALTER '${HLQ}.DEV.LOADLIB(EBVALI01)' NEWNAME('${HLQ}.DEV.LOADLIB(EBVAL_BK)')" 2>&1
        echo ""
        echo "Falha aplicada. O job EBJVALD deve ter ABEND S806."
        echo ""
        echo "INSTRUCOES DE DIAGNOSTICO:"
        echo "  1. Submeta EBJVALD e observe o ABEND"
        echo "  2. Verifique a STEPLIB no JCL"
        echo "  3. Liste os membros da LOADLIB"
        echo "  4. Restaure o membro e recompile se necessario"
        echo ""
        echo "PARA RESTAURAR:"
        echo "  Renomeie EBVAL_BK de volta para EBVALI01"
        echo "  Ou recompile com EBBUILD.jcl"
        ;;
    *)
        echo "CENARIO ${CENARIO} nao reconhecido."
        echo "Use um valor de 1 a 5."
        exit 4
        ;;
esac

echo ""
echo "================================================="
echo " Boa pratica de troubleshooting!"
echo "================================================="
