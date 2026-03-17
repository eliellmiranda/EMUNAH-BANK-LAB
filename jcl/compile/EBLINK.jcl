//* ------------------------------------------------------------
//* ARQUIVO      : EBLINK.jcl
//* CAMINHO LOCAL: jcl/compile/EBLINK.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBLINK)
//* FINALIDADE:
//* Fazer a link-edicao do modulo objeto gerado no EBCOMP.
//*
//* FLUXO ESPERADO:
//* 1. Ler o objeto temporario &&OBJSET.
//* 2. Invocar o binder / link-editor.
//* 3. Gerar o executavel na LOADLIB.
//* ------------------------------------------------------------
//EBLINK   JOB ,'EMUNAH LINK',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=IEWBLINK,PARM='RENT,REUS'
//* Executa a link-edicao do objeto compilado.
//SYSPRINT DD SYSOUT=*
//* Relatorio do binder.
//SYSLIN   DD DSN=&&OBJSET,DISP=(OLD,DELETE)
//* Dataset temporario recebido do EBCOMP com o modulo objeto.
//SYSLMOD  DD DSN=Z77948.EMUNAH.DEV.LOADLIB(EBCLLOAD),DISP=SHR
//* Biblioteca de carga onde sera gravado o executavel.
//SYSUT1   DD UNIT=SYSDA,SPACE=(TRK,(1,1))
//* Area temporaria de trabalho do binder.



JCL — EBLINK.jcl
copiar
//* ------------------------------------------------------------
//* ARQUIVO      : EBLINK.jcl
//* CAMINHO LOCAL: jcl/compile/EBLINK.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBLINK)
//* FINALIDADE:
//* Fazer a link-edicao do modulo objeto gerado no EBCOMP.
//*
//* FLUXO ESPERADO:
//* 1. Ler o objeto temporario &&OBJSET.
//* 2. Invocar o binder / link-editor.
//* 3. Gerar o executavel na LOADLIB.
//* ------------------------------------------------------------
//EBLINK   JOB ,'EMUNAH LINK',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=IEWBLINK,PARM='RENT,REUS'
//* Executa a link-edicao do objeto compilado.
//SYSPRINT DD SYSOUT=*
//* Relatorio do binder.
//SYSLIN   DD DSN=&&OBJSET,DISP=(OLD,DELETE)
//* Dataset temporario recebido do EBCOMP com o modulo objeto.
//SYSLMOD  DD DSN=Z77948.EMUNAH.DEV.LOADLIB(EBCLLOAD),DISP=SHR
//* Biblioteca de carga onde sera gravado o executavel.
//SYSUT1   DD UNIT=SYSDA,SPACE=(TRK,(1,1))
//* Area temporaria de trabalho do binder.





