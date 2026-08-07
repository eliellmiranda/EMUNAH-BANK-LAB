/* REXX *************************************************************/
/* MEMBRO   : EBCLI                                                 */
/* FUNCAO   : MENU INTERATIVO DE COMANDOS DO LABORATORIO            */
/********************************************************************/
ADDRESS TSO "CLS" /* Limpa a tela */

DO FOREVER
    SAY '================================================='
    SAY '         EMUNAH BANK - COMAND CENTER'
    SAY '================================================='
    SAY ' 1. RESETAR AMBIENTE (EBRESET)'
    SAY ' 2. GERAR MASSA DE TESTES (EBMOCKER)'
    SAY ' 3. EXECUTAR CADEIA BATCH (EBJCHAIN)'
    SAY ' 4. VERIFICAR STATUS DATASETS (EBDSLIST)'
    SAY ' 5. CONSULTA RAPIDA DE CONTA (MOCK)'
    SAY ' X. SAIR'
    SAY '-------------------------------------------------'
    SAY 'ESCOLHA UMA OPCAO:'
    PULL OPCAO

    SELECT
        WHEN OPCAO = 1 THEN "EXEC '"HLQ".DEV.REXX(EBRESET)'"
        WHEN OPCAO = 2 THEN "EXEC '"HLQ".DEV.REXX(EBMOCKER)'"
        WHEN OPCAO = 3 THEN "EXEC '"HLQ".DEV.REXX(EBSUBJCL)' 'EBJCHAIN'"
        WHEN OPCAO = 4 THEN "EXEC '"HLQ".DEV.REXX(EBDSLIST)'"
        WHEN OPCAO = 5 THEN DO
            SAY 'DIGITE A AGENCIA/CONTA:'
            PULL BUSCA
            SAY 'BUSCANDO...' BUSCA ' (FUNCIONALIDADE EM DESENVOLVIMENTO)'
        END
        WHEN OPCAO = 'X' THEN LEAVE
        OTHERWISE SAY 'OPCAO INVALIDA!'
    END
    SAY 'PRESSIONE ENTER PARA CONTINUAR...'
    PULL
    ADDRESS TSO "CLS"
END

SAY 'OBRIGADO POR UTILIZAR O EMUNAH BANK CLI!'
EXIT 0
