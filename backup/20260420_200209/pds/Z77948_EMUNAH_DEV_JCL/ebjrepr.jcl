//* ------------------------------------------------------------
//* ARQUIVO      : EBJREPR.jcl
//* CAMINHO LOCAL: jcl/batch/EBJREPR.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJREPR)
//* FINALIDADE:
//* Reprocessar lancamentos rejeitados que foram corrigidos.
//* Executado sob demanda, fora da cadeia batch normal.
//*
//* FLUXO ESPERADO:
//* 1. Ler o arquivo de rejeitos (ARQ.REJEITOS.SEQ).
//* 2. Revalidar cada registro com as mesmas regras.
//* 3. Gravar recuperados em ARQ.REPR.LANCTO.SEQ.
//* 4. Gravar nao-recuperados em ARQ.REPR.REJPERM.SEQ.
//* 5. Registrar auditoria de cada decisao.
//* ------------------------------------------------------------
//EBJREPR  JOB ,'EMUNAH REPR',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBREPR01
//* Programa de reprocessamento de rejeitos.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca do executavel EBREPR01.
//REJIN    DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,DISP=SHR
//* Arquivo de rejeitos a reprocessar.
//LCTOUT   DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Lancamentos recuperados pelo reprocessamento.
//REJOUT   DD DSN=Z77948.EMUNAH.ARQ.REPR.REJPERM.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=150,BLKSIZE=0)
//* Rejeitos permanentes que nao passaram na revalidacao.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria do reprocessamento.
//SYSOUT   DD SYSOUT=*
//* Saida geral do programa.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas.
