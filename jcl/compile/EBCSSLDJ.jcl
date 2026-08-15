//EBCSSLDJ JOB (ACCT),'COMP EBCSSLD',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID,REGION=0M
//*--------------------------------------------------------------*
//* COMPILE + BIND PARA PROGRAMA CICS COM DB2                    *
//* PROGRAMA : EBCSSLD                                           *
//* TRANSACAO: ESLD  (consulta de saldo)                         *
//*                                                              *
//* ORDEM CORRETA IBM PARA CICS + DB2:                           *
//*   PRECOMP  - DB2 precompilador  (fonte original -> DBRM)     *
//*   CICSTRAN - Tradutor CICS      (saida DB2 -> macros CICS)   *
//*   COMPILE  - Compilador COBOL   (saida CICS -> objeto)       *
//*   LKED     - Link-editor        (DSNELI + DFHECI)            *
//*   BINDPKG  - DB2 BIND PACKAGE + PLAN                         *
//*                                                              *
//* MOTIVO DA ORDEM:                                             *
//*   O precompilador DB2 precisa ver BEGIN DECLARE SECTION      *
//*   antes de qualquer SQL. Se o tradutor CICS rodar primeiro,  *
//*   ele insere declaracoes (DFHEIBLK, DFHCOMMAREA) antes do    *
//*   BEGIN DECLARE SECTION, confundindo o precompilador DB2.    *
//*   DB2 primeiro -> CICS segundo e o padrao IBM documentado.   *
//*                                                              *
//* NAO HA PASSO RUN: programa e invocado pelo CICS via ESLD     *
//*--------------------------------------------------------------*
//*
//*--- PASSO 1: DB2 PRECOMPILADOR ------------------------------*
//*  Le o fonte COBOL original diretamente.                      *
//*  Substitui EXEC SQL por comentarios + chamadas host.         *
//*  Gera o DBRM em DBRMLIB.                                     *
//*  Saida &&PREOUT e entregue ao tradutor CICS no passo 2.      *
//*--------------------------------------------------------------*
//PRECOMP  EXEC PGM=DSNHPC,
//         PARM='HOST(IBMCOB),APOST,SOURCE'
//STEPLIB  DD DSN=DB2V13.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=ELIEL.EMUNAH.DBRMLIB(EBCSSLD),DISP=OLD
//SYSCIN   DD DSN=&&PREOUT,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(5,5)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSLIB   DD DSN=ELIEL.EMUNAH.DEV.COPY,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSTERM  DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT2   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSIN    DD DSN=ELIEL.EMUNAH.DEV.COBOL(EBCSSLD),DISP=SHR
//*
//*--- PASSO 2: TRADUTOR CICS -----------------------------------*
//*  Le a saida do precompilador DB2 (&&PREOUT).                 *
//*  Converte EXEC CICS em chamadas DFHEI1.                      *
//*  Saida &&CICSIN e o fonte pronto para o compilador COBOL.    *
//*--------------------------------------------------------------*
//CICSTRAN EXEC PGM=DFHECP1$,
//         PARM='COBOL3,NOEDF,SP',
//         COND=(4,LT)
//STEPLIB  DD DSN=CICSTS61.CICS.SDFHLOAD,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSPUNCH DD DSN=&&CICSIN,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(5,5)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSIN    DD DSN=&&PREOUT,DISP=(OLD,DELETE)
//*
//*--- PASSO 3: COMPILADOR COBOL --------------------------------*
//*  Le o fonte com SQL substituido e macros CICS expandidas.    *
//*  NODYNAM: obrigatorio para CICS (modulos estaticos).         *
//*--------------------------------------------------------------*
//COMPILE  EXEC PGM=IGYCRCTL,
//         PARM='APOST,MAP,NODYNAM',
//         COND=(4,LT)
//STEPLIB  DD DSN=IGY.V6R4M0.SIGYCOMP,DISP=SHR
//SYSLIB   DD DSN=ELIEL.EMUNAH.DEV.COPY,DISP=SHR
//SYSIN    DD DSN=&&CICSIN,DISP=(OLD,DELETE)
//SYSLIN   DD DSN=&&OBJSET,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(5,5)),
//            DCB=(DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT2   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT3   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT4   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT5   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT6   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT7   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSMDECK DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT8   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT9   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT10  DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT11  DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT12  DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT13  DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT14  DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT15  DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//*
//*--- PASSO 4: LINK-EDITOR ------------------------------------*
//*  DSNELI  : interface DB2 Language Environment               *
//*  DFHECI  : stub de entrada CICS para programas COBOL        *
//*  RENT    : reentrante (obrigatorio para CICS)               *
//*--------------------------------------------------------------*
//LKED     EXEC PGM=IEWL,
//         PARM='LIST,MAP,XREF,RENT',
//         COND=(4,LT)
//SYSLIB   DD DSN=DB2V13.SDSNLOAD,DISP=SHR
//         DD DSN=CICSTS61.CICS.SDFHLOAD,DISP=SHR
//         DD DSN=CEE.SCEELKED,DISP=SHR
//SYSLIN   DD DSN=&&OBJSET,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//SYSLMOD  DD DSN=ELIEL.EMUNAH.ONLINE.LOADLIB(EBCSSLD),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSIN    DD *
  INCLUDE SYSLIB(DSNELI)
  INCLUDE SYSLIB(DFHECI)
  ENTRY EBCSSLD
/*
//*
//*--- PASSO 5: DB2 BIND ----------------------------------------*
//*--------------------------------------------------------------*
//BINDPKG  EXEC PGM=IKJEFT01,
//         COND=(4,LT)
//STEPLIB  DD DSN=DB2V13.SDSNLOAD,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DBD1)
  BIND PACKAGE(EMUNAH) MEMBER(EBCSSLD)            -
       LIBRARY('ELIEL.EMUNAH.DBRMLIB')            -
       ACTION(REPLACE) ISOLATION(CS) VALIDATE(BIND)
  BIND PLAN(EBCSSLD) PKLIST(EMUNAH.*)             -
       ACTION(REPLACE) ISOLATION(CS) VALIDATE(BIND)
  END
/*
