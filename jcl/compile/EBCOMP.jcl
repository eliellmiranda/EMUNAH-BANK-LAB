//* ------------------------------------------------------------
//* JOB: EBCOMP
//* FINALIDADE:
//* Executar a compilacao do programa COBOL informado em PGMNAME.
//*
//* FLUXO ESPERADO:
//* 1. Ler o fonte COBOL.
//* 2. Resolver os copybooks.
//* 3. Gerar o modulo objeto.
//* 4. Emitir listagem e mensagens de compilacao.
//* ------------------------------------------------------------
//EBCOMP   JOB ,'EMUNAH COMP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//COMPILE  EXEC PGM=IGYCRCTL,PARM='OBJECT,LIST,MAP,APOST,RENT'
//* Executa o compilador COBOL.
//SYSPRINT DD SYSOUT=*
//* Relatorio detalhado da compilacao.
//SYSLIB   DD DSN=Z77948.EMUNAH.DEV.COPY,DISP=SHR
//* Biblioteca de copybooks.
//SYSIN    DD DSN=Z77948.EMUNAH.DEV.COBOL(&PGMNAME),DISP=SHR
//* Fonte COBOL a ser compilado.
//SYSLIN   DD DSN=&&OBJ,DISP=(,PASS),UNIT=SYSDA,
//             SPACE=(TRK,(1,1)),DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
//* Dataset temporario que recebera o modulo objeto gerado na
//* compilacao para ser usado depois na link-edicao.
//SYSOUT   DD SYSOUT=*
//* Saida geral do compilador.