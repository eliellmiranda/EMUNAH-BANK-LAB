//EBMBMSJ  JOB (ACCT),'ASSEMBLE BMS',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID,REGION=0M
//*------------------------------------------------------------*
//* ASSEMBLY DO MAPA BMS MSBSLD — CICS TS 6.1                 *
//* FUNCAO : Montar o mapset MSBSLD para uso pela transacao    *
//*          ESLD (EBCSSLD) no CICS TS 6.1                     *
//*                                                            *
//* DFHMAPS nao existe neste ambiente — usa DFHBMSUP (CICS 6.1)*
//*                                                            *
//* PASSO 1 - BMSMAP : Assembla via ASMA90 + macros CICS       *
//*           Saida  : ELIEL.EMUNAH.ONLINE.LOADLIB(MSBSLD)     *
//* PASSO 2 - BMSCPY : Gera copybook simbolico (SYSPARM=DSECT) *
//*           Saida  : ELIEL.EMUNAH.DEV.COPY(EBMSLD)           *
//*------------------------------------------------------------*
//*
//*--- PASSO 1: ASSEMBLAR O MAPA (SYSPARM=MAP) -----------------*
//BMSMAP   EXEC PGM=ASMA90,
//         PARM='SYSPARM(MAP),DECK,NOOBJECT'
//STEPLIB  DD DSN=CICSTS61.CICS.SDFHLOAD,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSLIB   DD DSN=CICSTS61.CICS.SDFHMAC,DISP=SHR
//         DD DSN=SYS1.MACLIB,DISP=SHR
//         DD DSN=SYS1.MODGEN,DISP=SHR
//SYSIN    DD DSN=ELIEL.EMUNAH.DEV.BMS(MSBSLD),DISP=SHR
//SYSPUNCH DD DSN=&&OBJMAP,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//*
//*--- LINK-EDIT DO OBJETO GERADO ------------------------------*
//BMSLKED  EXEC PGM=IEWL,
//         PARM='LIST,MAP,XREF,RENT',
//         COND=(4,LT)
//SYSLIB   DD DSN=CICSTS61.CICS.SDFHLOAD,DISP=SHR
//         DD DSN=CEE.SCEELKED,DISP=SHR
//SYSLIN   DD DSN=&&OBJMAP,DISP=(OLD,DELETE)
//SYSLMOD  DD DSN=ELIEL.EMUNAH.ONLINE.LOADLIB(MSBSLD),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(TRK,(5,5))
//*
//*--- PASSO 2: GERAR COPYBOOK SIMBOLICO (SYSPARM=DSECT) -------*
//BMSCPY   EXEC PGM=ASMA90,
//         PARM='SYSPARM(DSECT),DECK,NOOBJECT',
//         COND=(4,LT)
//STEPLIB  DD DSN=CICSTS61.CICS.SDFHLOAD,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSLIB   DD DSN=CICSTS61.CICS.SDFHMAC,DISP=SHR
//         DD DSN=SYS1.MACLIB,DISP=SHR
//         DD DSN=SYS1.MODGEN,DISP=SHR
//SYSIN    DD DSN=ELIEL.EMUNAH.DEV.BMS(MSBSLD),DISP=SHR
//SYSPUNCH DD DSN=ELIEL.EMUNAH.DEV.COPY(EBMSLD),DISP=SHR
