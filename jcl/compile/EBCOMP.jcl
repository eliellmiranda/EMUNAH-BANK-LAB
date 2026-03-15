//* ------------------------------------------------------------
//* JOB: EBCOMP
//* FINALIDADE:
//* Executar a compilacao do programa COBOL EBCLLOAD.
//*
//* FLUXO ESPERADO:
//* 1. Ler o fonte COBOL.
//* 2. Resolver os copybooks.
//* 3. Gerar o modulo objeto.
//* 4. Emitir listagem e mensagens de compilacao.
//* ------------------------------------------------------------
//EBCOMP   JOB ,'EMUNAH COMP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=IGYCRCTL
//* Executa o compilador COBOL.
//SYSIN    DD DSN=Z77948.EMUNAH.DEV.COBOL(EBCLLOAD),DISP=SHR
//* Fonte COBOL a ser compilado.
//SYSLIB   DD DSN=Z77948.EMUNAH.DEV.COPY,DISP=SHR
//* Biblioteca de copybooks.
//SYSLIN   DD DSN=&&OBJSET,DISP=(,PASS),UNIT=SYSDA,
//             SPACE=(TRK,(1,1)),DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//* Dataset temporario que recebera o modulo objeto gerado na
//* compilacao para ser usado depois na link-edicao.
//SYSPRINT DD SYSOUT=*
//* Relatorio detalhado da compilacao.
//SYSOUT   DD SYSOUT=*
//* Saida geral do compilador.