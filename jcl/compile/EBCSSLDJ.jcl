//EBCSSLDJ JOB (ACCT),'COMP EBCSSLD',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID,REGION=0M
//*--------------------------------------------------------------*
//* COMPILE + BIND PARA PROGRAMA CICS COM DB2                    *
//* PROGRAMA : EBCSSLD                                           *
//* TRANSACAO: ESLD  (consulta de saldo)                         *
//*                                                              *
//* FLUXO DE 4 PASSOS:                                           *
//*   CICSTRAN  - Tradutor CICS  (EXEC CICS -> macros)           *
//*   COMPILE   - Compilador COBOL (fonte traduzido + SQLCA)     *
//*   LKED      - Link-editor   (DSNELI + DFHECI obrigatorios)   *
//*   BINDPKG   - DB2 BIND PACKAGE + PLAN                        *
//*                                                              *
//* NAO HA PASSO RUN: programa e invocado pelo CICS via ESLD     *
//*--------------------------------------------------------------*
//*
//*--- PASSO 1: TRADUTOR CICS -----------------------------------*
//*  Converte EXEC CICS em chamadas DFHEI1 que o compilador      *
//*  COBOL entende. A saida (&&CICSIN) vai direto ao DB2         *
//*  precompilador no passo seguinte.                            *
//*  DFHECP1$ = translator CICS TS 6.1                          *
//*--------------------------------------------------------------*
//CICSTRAN EXEC PGM=DFHECP1$,
//         PARM='COBOL3,NOEDF,SP'
//STEPLIB  DD DSN=DFH610.SDFHLOAD,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSPUNCH DD DSN=&&CICSIN,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(5,5)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSIN    DD DSN=ELIEL.EMUNAH.DEV.COBOL(EBCSSLD),DISP=SHR
//*
//*--- PASSO 2: DB2 PRECOMPILADOR ------------------------------*
//*  Le o fonte ja traduzido pelo CICS (&&CICSIN).               *
//*  Extrai os blocos EXEC SQL e gera o DBRM (DBRMLIB).          *
//*  Saida &&SYSCIN e o fonte modificado para o compilador COBOL.*
//*--------------------------------------------------------------*
//PRECOMP  EXEC PGM=DSNHPC,
//         PARM='HOST(IBMCOB),APOST,SOURCE',
//         COND=(4,LT)
//STEPLIB  DD DSN=DB2V13.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=ELIEL.EMUNAH.DBRMLIB(EBCSSLD),DISP=OLD
//SYSCIN   DD DSN=&&SYSCIN,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(5,5)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSLIB   DD DSN=ELIEL.EMUNAH.DEV.COPY,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSTERM  DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSUT2   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSIN    DD DSN=&&CICSIN,DISP=(OLD,DELETE)
//*
//*--- PASSO 3: COMPILADOR COBOL --------------------------------*
//*  Le o fonte com macros CICS e SQL ja substituidos (&&SYSCIN).*
//*  Parm NODYNAM necessario para CICS (modulos estaticos).      *
//*--------------------------------------------------------------*
//COMPILE  EXEC PGM=IGYCRCTL,
//         PARM='APOST,MAP,NODYNAM',
//         COND=(4,LT)
//STEPLIB  DD DSN=IGY.V6R4M0.SIGYCOMP,DISP=SHR
//SYSLIB   DD DSN=ELIEL.EMUNAH.DEV.COPY,DISP=SHR
//SYSIN    DD DSN=&&SYSCIN,DISP=(OLD,DELETE)
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
//*  Tres INCLUDE obrigatorios para programas CICS com DB2:      *
//*    DSNELI  : interface DB2 Language Environment              *
//*    DFHECI  : stub de entrada CICS para programas COBOL       *
//*    DFHEICD : definicoes de constantes CICS (DFHRESP etc.)    *
//*  LOADLIB online e separada da batch (ONLINE.LOADLIB).        *
//*--------------------------------------------------------------*
//LKED     EXEC PGM=IEWL,
//         PARM='LIST,MAP,XREF,RENT',
//         COND=(4,LT)
//SYSLIB   DD DSN=DB2V13.SDSNLOAD,DISP=SHR
//         DD DSN=DFH610.SDFHLOAD,DISP=SHR
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
//*  BIND PACKAGE: registra o DBRM gerado no passo PRECOMP.      *
//*  BIND PLAN   : cria o plano EBCSSLD que o CICS usa para       *
//*                localizar todos os packages EMUNAH.*.           *
//*  ISOLATION(CS): Cursor Stability — padrao correto para CICS.  *
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
