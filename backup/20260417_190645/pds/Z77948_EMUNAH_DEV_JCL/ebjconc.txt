//* ------------------------------------------------------------
//* ARQUIVO      : EBJCONC.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCONC.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCONC)
//* FINALIDADE:
//* Conciliar os movimentos processados e gerar evidencias da
//* conciliacao do dia.
//*
//* FLUXO ESPERADO:
//* 1. Ler MOVTIN em ARQ.LANCTO.ESDS.
//* 2. Comparar totais processados.
//* 3. Gerar arquivo de saida em ARQ.CONCIL.SEQ.
//* ------------------------------------------------------------
//EBJCONC  JOB ,'EMUNAH CONC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBCONC01
//* Programa de conciliacao do processamento.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca do executavel EBCONC01.
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* Entrada de movimentos ja validados/processados.
//CONCOUT  DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=MOD
//* Saida com o relatorio de conciliacao.
//SYSOUT   DD SYSOUT=*
//* Saida geral do programa.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas.
