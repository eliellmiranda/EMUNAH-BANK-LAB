/* REXX *************************************************************/
/* MEMBRO   : EBMOCKER                                              */
/* FUNCAO   : GERAR MASSA DE DADOS PARA TESTE BATCH                 */
/********************************************************************/
HLQ = 'ELIEL.EMUNAH'
SAY 'QUANTAS TRANSACOES DESEJA GERAR?'
PULL QTD

IF \DATATYPE(QTD, 'W') THEN DO
    SAY 'ERRO: Informe um numero inteiro.'
    EXIT 8
END

OUT_DSN = "'"HLQ".ARQ.ENTRADA.SEQ'"
"ALLOC F(OUT) DA("OUT_DSN") MOD"

SAY 'GERANDO' QTD 'LANCAMENTOS EM' OUT_DSN '...'

DO I = 1 TO QTD
    AGENCIA = RIGHT(RANDOM(1, 9999), 4, '0')
    CONTA   = RIGHT(RANDOM(1, 99999999), 8, '0')
    VALOR   = RIGHT(RANDOM(1, 1000000), 10, '0') /* Valor em centavos */
    TIPO    = WORD('C D', RANDOM(1, 2))

    /* Monta registro conforme layout CPLCT001 (exemplo 80 bytes) */
    REGISTRO = AGENCIA || CONTA || VALOR || TIPO
    REGISTRO = OVERLAY(REGISTRO, COPIES(' ', 80))

    PUSH REGISTRO
    "EXECIO 1 DISKW OUT"
END

"EXECIO 0 DISKW OUT (FINIS"
"FREE F(OUT)"

SAY '>>> MASSA DE DADOS GERADA COM SUCESSO! <<<'
EXIT 0
