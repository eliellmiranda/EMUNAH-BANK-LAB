//EBJCONCH JOB ,'EMUNAH HML CONC',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*-----------------------------------------------------------------*
//* JOB      : EBJCONCH                                             *
//* BIBLIOTECA: Z77948.EMUNAH.HML.JCL                               *
//* FUNCAO   : EXECUTAR A CONCILIACAO EM HOMOLOGACAO                *
//*                                                                 *
//* O QUE ESTE JOB FAZ:                                             *
//* - Executa o programa EBCONC01                                   *
//* - Le um arquivo de movimentos                                   *
//* - Gera um arquivo sequencial com o resultado da conciliacao     *
//*                                                                 *
//* OBSERVACOES OPERACIONAIS:                                       *
//* - MOVTIN eh a entrada de movimentos a conciliar                 *
//* - CONCOUT eh a saida sequencial da conciliacao                  *
//* - Ajuste o STEPLIB quando existir HML.LOADLIB                   *
//*-----------------------------------------------------------------*
//STEP1    EXEC PGM=EBCONC01
//*
//* LOADLIB UTILIZADA NA EXECUCAO
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*
//* ENTRADA DE MOVIMENTOS
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.VALID.SEQ,DISP=SHR
//*
//* SAIDA DA CONCILIACAO
//CONCOUT  DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=OLD
//*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
