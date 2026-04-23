//* ------------------------------------------------------------
//* ARQUIVO      : EBJPOST.jcl
//* CAMINHO LOCAL: jcl/batch/EBJPOST.jcl
//*
//* CONTEXTO DIDATICO:
//* Aplicar os lançamentos válidos nas contas do laboratório.
//*
//* PAPEL NO LAB:
//* Step de postagem financeira.
//*
//* FLUXO RESUMIDO:
//* 1. Lê MOVTIN (válidos).
//* 2. Atualiza CONTA.KSDS.
//* 3. Registra movimentos em trilha operacional e auditoria.
//*
//* OBSERVACOES:
//* - O JCL desta versão também fornece REJEITOS para
//* registrar falhas de negócio detectadas na postagem.
//* ------------------------------------------------------------
//EBJPOST  JOB ,'EMUNAH POST',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBPOST01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=OLD
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,DISP=MOD
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
