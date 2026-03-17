//* ------------------------------------------------------------
//* ARQUIVO      : EBJVALD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJVALD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJVALD)
//* FINALIDADE:
//* Validar o lote bruto do dia.
//*
//* FLUXO ESPERADO:
//* 1. Ler ARQ.ENTRADA.SEQ.
//* 2. Chamar o programa EBVALI01.
//* 3. Gravar validos em ARQ.LANCTO.ESDS.
//* 4. Gravar rejeitos em ARQ.REJEITO.SEQ.
//* ------------------------------------------------------------
//EBJVALD  JOB ,'EMUNAH VALD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBVALI01
//* Programa de validacao do lote bruto.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca onde esta o executavel EBVALI01.
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,DISP=SHR
//* Lote bruto do dia.
//VALIDOS  DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* Saida de lancamentos aprovados pela validacao.
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITO.SEQ,DISP=MOD
//* Saida dos registros rejeitados.
//SYSOUT   DD SYSOUT=*
//* Saida geral do programa.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas da execucao.