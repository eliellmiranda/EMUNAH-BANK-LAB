//* ------------------------------------------------------------
//* ARQUIVO      : EBJEXTR.jcl
//* CAMINHO LOCAL: jcl/batch/EBJEXTR.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJEXTR)
//* FINALIDADE:
//* Gerar o extrato de movimentos do dia a partir dos
//* lancamentos ja validados e processados.
//*
//* FLUXO ESPERADO:
//* 1. Ler MOVTIN em ARQ.LANCTO.ESDS.
//* 2. Formatar cada movimento como linha de extrato.
//* 3. Gerar cabecalho, detalhe e rodape com totais.
//* 4. Gravar resultado em ARQ.EXTRATO.SEQ.
//* ------------------------------------------------------------
//EBJEXTR  JOB ,'EMUNAH EXTR',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBEXTR01
//* Programa de geracao de extratos.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca do executavel EBEXTR01.
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* Entrada de movimentos validados/processados.
//EXTROUT  DD DSN=Z77948.EMUNAH.ARQ.EXTRATO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//* Saida com o extrato formatado do dia.
//SYSOUT   DD SYSOUT=*
//* Saida geral do programa.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas.
