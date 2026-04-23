//* ------------------------------------------------------------
//* ARQUIVO      : EBJVALD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJVALD.jcl
//*
//* CONTEXTO DIDATICO:
//* Executar a validação de layout e regras de negócio dos lançamentos do dia.
//*
//* PAPEL NO LAB:
//* Primeiro processamento funcional da cadeia.
//*
//* FLUXO RESUMIDO:
//* 1. Lê ENTRADA.SEQ.
//* 2. Confere conta/status/valor/tipo.
//* 3. Grava válidos, rejeitos e auditoria.
//*
//* OBSERVACOES:
//* - O JCL desta versão já fornece CONTA ao programa de
//* validação.
//* ------------------------------------------------------------
//EBJVALD  JOB ,'EMUNAH VALD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBVALI01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,DISP=SHR
//VALIDOS  DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=OLD
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,DISP=MOD
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
