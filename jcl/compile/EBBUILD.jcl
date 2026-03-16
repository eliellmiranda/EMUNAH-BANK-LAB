//* ------------------------------------------------------------
//* JOB: EBBUILD
//* FINALIDADE:
//* Executar compilacao e link-edicao em um unico job usando IGYWCL.
//*
//* FLUXO ESPERADO:
//* 1. Ler o fonte COBOL.
//* 2. Resolver copybooks.
//* 3. Compilar e link-editar.
//* 4. Gerar o modulo na LOADLIB.
//* ------------------------------------------------------------
//EBBUILD  JOB ,'EMUNAH BUILD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//CL       EXEC IGYWCL
//* Procedure IBM que compila e link-edita de uma vez.
//COBOL.SYSIN   DD DSN=Z77948.EMUNAH.DEV.COBOL(EBCLLOAD),DISP=SHR
//* Fonte COBOL alvo do build.
//COBOL.SYSLIB  DD DSN=Z77948.EMUNAH.DEV.COPY,DISP=SHR
//* Copybooks utilizados na compilacao.
//LKED.SYSLMOD  DD DSN=Z77948.EMUNAH.DEV.LOADLIB(EBCLLOAD),DISP=SHR
//* Saida do modulo executavel.
//LKED.SYSPRINT DD SYSOUT=*
//* Relatorio da fase de link-edicao.