//* ------------------------------------------------------------
//* ARQUIVO      : EBJEOD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJEOD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJEOD)
//* FINALIDADE:
//* Executar o fechamento diario (End-Of-Day) do laboratorio.
//*
//* FLUXO ESPERADO:
//* 1. Ler o arquivo de conciliacao do dia.
//* 2. Totalizar contas no KSDS.
//* 3. Gerar relatorio de fechamento.
//* 4. Gravar registro de auditoria com status do dia.
//* ------------------------------------------------------------
//EBJEOD   JOB ,'EMUNAH EOD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBJEOD01
//* Programa de fechamento diario.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca do executavel EBJEOD01.
//CONCIN   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=SHR
//* Arquivo de conciliacao gerado pelo EBJCONC.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* Arquivo master de contas para totalizacao.
//FECHOUT  DD DSN=Z77948.EMUNAH.ARQ.FECHTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//* Relatorio de fechamento do dia.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria do fechamento.
//SYSOUT   DD SYSOUT=*
//* Saida geral do programa.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas.
