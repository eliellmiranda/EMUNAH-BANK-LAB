//EBJSMKH  JOB ,'EMUNAH HML SMOKE',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*-----------------------------------------------------------------*
//* JOB      : EBJSMKH                                              *
//* BIBLIOTECA: Z77948.EMUNAH.HML.JCL                               *
//* FUNCAO   : EXECUTAR O SMOKE TEST DO AMBIENTE HML                *
//*                                                                 *
//* O QUE ESTE JOB FAZ:                                             *
//* - Executa o programa EBSMKH01                                   *
//* - Verifica se a carga executavel esta acessivel                 *
//* - Valida minimamente o ambiente antes de testes maiores         *
//*                                                                 *
//* OBSERVACAO IMPORTANTE:                                          *
//* - Quando existir uma HML.LOADLIB, o STEPLIB deve apontar        *
//*   preferencialmente para ela                                    *
//* - Enquanto isso nao existir, pode ser usado DEV.LOADLIB         *
//*-----------------------------------------------------------------*
//STEP1    EXEC PGM=EBSMKH01
//*
//* LOADLIB UTILIZADA NA EXECUCAO
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*
//* SAIDAS PADRAO DE SPOOL
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
