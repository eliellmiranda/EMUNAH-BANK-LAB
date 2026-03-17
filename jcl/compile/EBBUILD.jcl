//* ------------------------------------------------------------
//* ARQUIVO      : EBBUILD.jcl
//* CAMINHO LOCAL: jcl/compile/EBBUILD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBBUILD)
//* FINALIDADE:
//* Compilar e link-editar em um unico job.
//*
//* FLUXO ESPERADO:
//* 1. Ler o fonte COBOL.
//* 2. Resolver copybooks.
//* 3. Compilar e link-editar usando IGYWCL.
//* 4. Gravar o executavel na LOADLIB.
//* ------------------------------------------------------------
//EBBUILD  JOB ,'EMUNAH BUILD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//CL       EXEC IGYWCL
//* Procedure catalogada IBM que faz compile + link.
//COBOL.SYSIN   DD DSN=Z77948.EMUNAH.DEV.COBOL(EBCLLOAD),DISP=SHR
//* Fonte COBOL principal da compilacao.
//COBOL.SYSLIB  DD DSN=Z77948.EMUNAH.DEV.COPY,DISP=SHR
//* Biblioteca de copybooks.
//LKED.SYSLMOD  DD DSN=Z77948.EMUNAH.DEV.LOADLIB(EBCLLOAD),DISP=SHR
//* Destino final do executavel.
//LKED.SYSPRINT DD SYSOUT=*
//* Relatorio do link-editor.