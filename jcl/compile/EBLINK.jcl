//* ------------------------------------------------------------
//* JOB: EBLINK
//* FINALIDADE:
//* Realizar a link-edicao do modulo objeto gerado no EBCOMP.
//*
//* FLUXO ESPERADO:
//* 1. Ler o objeto temporario.
//* 2. Invocar o linkage editor.
//* 3. Gravar o modulo executavel na LOADLIB.
//* ------------------------------------------------------------
//EBLINK   JOB ,'EMUNAH LINK',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//LINK     EXEC PGM=IEWBLINK,PARM='RENT,REUS'
//* Executa o linkage editor.
//SYSPRINT DD SYSOUT=*
//* Listagem detalhada do link-edit.
//SYSLIN   DD DSN=&&OBJ,DISP=(OLD,DELETE)
//* Modulo objeto vindo do passo de compilacao.
//SYSLMOD  DD DSN=Z77948.EMUNAH.DEV.LOADLIB(&PGMNAME),DISP=SHR
//* Biblioteca que recebera o executavel final.