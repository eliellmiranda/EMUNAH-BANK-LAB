//EBJSYNC  JOB (EMUNAH),'SYNC VSAM DB2',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*===================================================================*
//* JOB      : EBJSYNC                                                *
//* FUNCAO   : SINCRONIZACAO DIARIA DO VSAM PARA O DB2                *
//* FREQUENCIA: DIARIA (D0) - APOS O FECHAMENTO DO BATCH (EOD)        *
//*===================================================================*
//*
//*===================================================================*
//* STEP 01: SMOKE TEST DO AMBIENTE (VALIDA SE O JOB PODE RODAR)      *
//*===================================================================*
//STEP01   EXEC PGM=EBSMKH01
//STEPLIB  DD DSN=Z77948.EMUNAH.LOADLIB,DISP=SHR
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
//*===================================================================*
//* STEP 02: SINCRONIZAR MASTER DE CONTAS (UPSERT VSAM -> DB2)        *
//*===================================================================*
//STEP02   EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(4,LT)
//STEPLIB  DD DSN=Z77948.EMUNAH.LOADLIB,DISP=SHR
//         DD DSN=DSN.V13R1M0.SDSNLOAD,DISP=SHR  <-- Loadlib do DB2
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
//*===================================================================*
//* STEP 03: SINCRONIZAR CLIENTES (UPSERT VSAM -> DB2)                *
//* (Placeholder para o futuro programa EBSYNC02)                     *
//*===================================================================*
//STEP03   EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(4,LT)
//STEPLIB  DD DSN=Z77948.EMUNAH.LOADLIB,DISP=SHR
//         DD DSN=DSN.V13R1M0.SDSNLOAD,DISP=SHR
//CLIENTES DD DSN=Z77948.EMUNAH.ARQ.CLIENTES.KSDS,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2T)
  RUN PROGRAM(EBSYNC02) PLAN(PLSYNC02)
  END
/*
//*
//*===================================================================*
//* STEP 04: CARGA DE MOVIMENTOS TRANSACIONAIS (APPEND)               *
//* (Placeholder para o futuro programa EBSYNC03)                     *
//*===================================================================*
//STEP04   EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(4,LT)
//STEPLIB  DD DSN=Z77948.EMUNAH.LOADLIB,DISP=SHR
//         DD DSN=DSN.V13R1M0.SDSNLOAD,DISP=SHR
//EXTRATO  DD DSN=Z77948.EMUNAH.ARQ.EXTRATO.GDG(0),DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2T)
  RUN PROGRAM(EBSYNC03) PLAN(PLSYNC03)
  END
/*
//