//EBJCHAIN JOB (EMUNAH),'CADEIA BATCH EOD',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*===================================================================*
//* JOB      : EBJCHAIN                                               *
//* FUNCAO   : EXECUCAO SEQUENCIAL DE TODO O FECHAMENTO DIARIO (EOD)  *
//* REGRAS   : CONDICIONADO A SUCESSO (RC <= 4) DOS PASSOS ANTERIORES *
//*===================================================================*
//*
//*===================================================================*
//* STEP 01: BACKUP PRE-PROCESSAMENTO DOS KSDS DE DADOS               *
//*===================================================================*
//STEP01   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//BKPCONTA DD DSN=Z77948.EMUNAH.BKP.CONTA.SEQ,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(5,5),RLSE),
//            DCB=(RECFM=FB,LRECL=100,BLKSIZE=0)
//SYSIN    DD *
  REPRO INFILE(CONTA) OUTFILE(BKPCONTA) REPLACE
/*
//*
//* --- SE O BACKUP FUNCIONOU (RC <= 4), INICIA O PROCESSAMENTO ---
// IF (STEP01.RC <= 4) THEN
//*
//*===================================================================*
//* STEP 02: CARGA E VALIDACAO DOS LANCAMENTOS (EBVALI01)             *
//*===================================================================*
//STEP02   EXEC PGM=EBVALI01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,DISP=SHR
//SAIDAOK  DD DSN=Z77948.EMUNAH.ARQ.VALIDOS.SEQ,
//            DISP=(NEW,PASS,DELETE),
//            SPACE=(TRK,(5,5),RLSE)
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITO.SEQ,DISP=MOD
//SYSOUT   DD SYSOUT=*
//*
//* --- SE A VALIDACAO PASSOU, FAZ A POSTAGEM (ATUALIZA SALDO) ----
// IF (STEP02.RC <= 4) THEN
//*
//*===================================================================*
//* STEP 03: POSTAGEM E ATUALIZACAO DO MASTER (EBPOST01)              *
//*===================================================================*
//STEP03   EXEC PGM=EBPOST01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//MOVTO    DD DSN=Z77948.EMUNAH.ARQ.VALIDOS.SEQ,DISP=(OLD,DELETE)
//EXTRATO  DD DSN=Z77948.EMUNAH.ARQ.EXTRATO.SEQ,DISP=MOD
//SYSOUT   DD SYSOUT=*
//*
//* --- SE A POSTAGEM FOI SUCESSO, ATUALIZA O BANCO RELACIONAL ----
// IF (STEP03.RC <= 4) THEN
//*
//*===================================================================*
//* STEP 04: SINCRONIZACAO DO VSAM PARA O DB2 (EBSYNC01)              *
//*===================================================================*
//STEP04   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//         DD DSN=DSN.V13R1M0.SDSNLOAD,DISP=SHR
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2T)
  RUN PROGRAM(EBSYNC01) PLAN(PLSYNC01)
  END
/*
//*
//* --- FECHAMENTO DOS BLOCOS CONDICIONAIS IF ---------------------
// ENDIF  (FIM DO IF DO STEP03)
// ENDIF  (FIM DO IF DO STEP02)
// ENDIF  (FIM DO IF DO STEP01)
//*===================================================================*
//* FIM DA CADEIA BATCH EMUNAH BANK LAB                               *
//*===================================================================*
//