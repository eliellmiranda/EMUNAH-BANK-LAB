//* ============================================================
//* ARQUIVO      : EBDEPLOY.jcl
//* CAMINHO LOCAL: jcl/deploy/EBDEPLOY.jcl
//* HOST / PDS   : ELIEL.EMUNAH.DEV.JCL(EBDEPLOY)
//*
//* FINALIDADE:
//* Compilar e link-editar toda a cadeia de programas COBOL
//* do laboratorio usando IGYWCL.
//*
//* QUANDO USAR:
//* - Apos alteracao em copybooks (todos os programas devem
//*   ser recompilados para capturar a nova versao)
//* - Deploy inicial do ambiente apos EBALLOC + EBDEFGDG
//*
//* LOGICA:
//* Cada step compila e link-edita diretamente na LOADLIB
//* oficial. Se algum step retornar RC >= 8, os steps
//* seguintes sao abortados pelo COND=(4,LT).
//*
//* CORRECAO: Removido padrao &&TMPLOAD + PROMOTE que causava
//* RC=12 no LKED por alocacao VIO no ambiente SMS do zXplore.
//* Os modulos agora sao gravados direto em EMUNAH.DEV.LOADLIB.
//* ============================================================
//EBDEPLOY JOB ,'EMUNAH DEPLOY',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//         JCLLIB ORDER=(IGY.V6R4M0.SIGYPROC)
/*JOBPARM LINES=9999
//*
//CL01     EXEC IGYWCL
//* CL01:      EBCLDB01 - carga inicial
//COBOL.SYSIN   DD DSN=ELIEL.EMUNAH.DEV.COBOL(EBCLDB01),DISP=SHR
//COBOL.SYSLIB  DD DSN=ELIEL.EMUNAH.DEV.COPY,DISP=SHR
//LKED.SYSLMOD  DD DSN=ELIEL.EMUNAH.DEV.LOADLIB(EBCLDB01),DISP=SHR
//LKED.SYSPRINT DD SYSOUT=*
