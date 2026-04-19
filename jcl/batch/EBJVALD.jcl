//* ------------------------------------------------------------
//* ARQUIVO      : EBJVALD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJVALD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJVALD)
//* FINALIDADE:
//* Executar o programa EBVALI01 para validar os lancamentos
//* do dia recebidos em ARQ.ENTRADA.SEQ.
//*
//* FLUXO ESPERADO:
//* 1. Ler ARQ.ENTRADA.SEQ (ENTRADA).
//* 2. Validar tipo, valor, agencia e conta.
//* 3. Gravar lancamentos aprovados em ARQ.LANCTO.ESDS (VALIDOS).
//* 4. Gravar lancamentos rejeitados em ARQ.REJEITOS.SEQ (REJEITOS).
//* 5. Registrar eventos no arquivo de auditoria.
//* ------------------------------------------------------------
//EBJVALD  JOB ,'EMUNAH VALD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBVALI01
//* Programa de validacao dos lancamentos de entrada.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca onde esta o modulo executavel EBVALI01.
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,DISP=SHR
//* Arquivo sequencial de entrada com lancamentos do dia.
//VALIDOS  DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* Arquivo VSAM ESDS de saida para lancamentos validos.
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(MOD,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Arquivo sequencial de saida para lancamentos rejeitados.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Arquivo sequencial de auditoria do processamento.
//SYSOUT   DD SYSOUT=*
//* Saida geral do step para o spool.
//SYSPRINT DD SYSOUT=*
//* Saida detalhada, relatorio e mensagens do programa.
