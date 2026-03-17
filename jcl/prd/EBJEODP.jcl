//EBJEODP  JOB ,'EMUNAH PRD EOD',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*-----------------------------------------------------------------*
//* JOB      : EBJEODP                                              *
//* BIBLIOTECA: Z77948.EMUNAH.PRD.JCL                               *
//* FUNCAO   : EXECUTAR O FECHAMENTO EOD DO LAB                     *
//*                                                                 *
//* FLUXO DE PROCESSAMENTO:                                         *
//* 1) GERA BACKUP DAS CONTAS                                       *
//* 2) POSTA MOVIMENTOS                                             *
//* 3) CONCILIA O RESULTADO                                         *
//*                                                                 *
//* OBJETIVO:                                                       *
//* - Simular um fechamento batch mais proximo de um fluxo real     *
//* - Preservar o estado das contas antes do update                 *
//* - Garantir trilha e conferencia do processamento                *
//*-----------------------------------------------------------------*
//STEPBKP  EXEC PGM=EBBACK01
//*
//* LOADLIB OFICIAL DE PRODUCAO
//STEPLIB  DD DSN=Z77948.EMUNAH.PRD.LOADLIB,DISP=SHR
//*
//* LEITURA DO CADASTRO DE CONTAS
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//*
//* SAIDA DO BACKUP EOD
//BAKOUT   DD DSN=Z77948.EMUNAH.BAK.CONTA.SEQ,DISP=OLD
//*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//IFPOST   IF (STEPBKP.RC LT 8) THEN
//*
//STEPPOST EXEC PGM=EBPOST01
//STEPLIB  DD DSN=Z77948.EMUNAH.PRD.LOADLIB,DISP=SHR
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.VALID.SEQ,DISP=SHR
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=OLD
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//STEPCONC EXEC PGM=EBCONC01
//STEPLIB  DD DSN=Z77948.EMUNAH.PRD.LOADLIB,DISP=SHR
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.VALID.SEQ,DISP=SHR
//CONCOUT  DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=OLD
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//ENDIF    ENDIF