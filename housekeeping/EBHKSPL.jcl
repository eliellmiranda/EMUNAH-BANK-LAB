//EBHKSPL  JOB (ACCT),'EMUNAH HSKP-SPOOL',CLASS=A,MSGCLASS=H,
//             NOTIFY=&SYSUID,REGION=0M
//*------------------------------------------------------------------
//* EBHKSPL - EMUNAH BANK LAB - MONITOR DE UTILIZACAO DO SPOOL (JES2)
//*
//* Roda o REXX EBHKSPL via TSO/E em batch (IKJEFT01), que consulta
//* o SDSF e classifica a severidade. RC do step MONITOR:
//*   0  = OK              (spool < 80%)
//*   4  = ATENCAO          (spool >= 80%)
//*   8  = ALERTA           (spool >= 90%)
//*   12 = CRITICO          (spool >= 95%)
//*
//* AJUSTE: SYSEXEC abaixo deve apontar para a biblioteca onde voce
//* vai colocar o membro EBHKSPL (o .rexx) depois de subir via Zowe/
//* upload. Sugestao de nome: ELIEL.EMUNAH.REXX.EXEC (ou a biblioteca
//* de EXECs que voce ja usa - ajuste para a real).
//*------------------------------------------------------------------
//MONITOR  EXEC PGM=IKJEFT01,DYNAMNBR=25,REGION=0M
//SYSEXEC  DD   DSN=ELIEL.EMUNAH.REXX.EXEC,DISP=SHR
//SYSTSPRT DD   SYSOUT=*
//SYSPRINT DD   SYSOUT=*
//SYSTSIN  DD   *
  %EBHKSPL
/*
//*
//* --- OPCIONAL: rodar o EBHKPUR em modo REPORT (dry-run) sempre
//* --- que o MONITOR voltar CRITICO (RC=12). Comecar em modo REPORT
//* --- e' de proposito - so promova para PURGE depois de acompanhar
//* --- os relatorios por um tempo e confiar na whitelist.
//* --- Para ativar, remova o "*" no inicio das linhas abaixo.
//*PURGECK EXEC PGM=IKJEFT01,DYNAMNBR=25,REGION=0M,
//*             COND=(12,NE,MONITOR)
//*SYSEXEC DD   DSN=ELIEL.EMUNAH.REXX.EXEC,DISP=SHR
//*SYSTSPRT DD  SYSOUT=*
//*SYSPRINT DD  SYSOUT=*
//*SYSTSIN  DD  *
//*  %EBHKPUR REPORT
//*/*
