//* ============================================================
//* ARQUIVO      : EBBLDCLI.jcl
//* CAMINHO LOCAL: jcl/deploy/EBBLDCLI.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBBLDCLI)
//*
//* FINALIDADE:
//*   Build isolado do programa EBCLLOAD (carga de clientes/contas).
//*   Recompila e link-edita usando o copybook CPCLI001 atualizado.
//*
//* QUANDO USAR:
//*   - Apos correcao/restauracao do copybook CPCLI001
//*   - Para resolver FS=37 no OPEN do CLIENTE-KSDS
//*     (modulo na LOADLIB com layout antigo vs cluster atual)
//*   - Build pontual sem precisar rodar o EBDEPLOY completo
//*
//* CODIGOS DE RETORNO:
//*   RC 0 ou 4 = compilacao OK, modulo gravado na LOADLIB
//*   RC >= 8   = erro de compilacao - verificar SYSPRINT
//* ============================================================
//EBBLDCLI JOB ,'EMUNAH BUILD CLI',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//CL01     EXEC IGYWCL
//*           Recompila EBCLLOAD com CPCLI001 restaurado (80 bytes)
//COBOL.SYSIN   DD DSN=Z77948.EMUNAH.DEV.COBOL(EBCLLOAD),DISP=SHR
//COBOL.SYSLIB  DD DSN=Z77948.EMUNAH.DEV.COPY,DISP=SHR
//LKED.SYSLMOD  DD DSN=Z77948.EMUNAH.DEV.LOADLIB(EBCLLOAD),DISP=SHR
//LKED.SYSPRINT DD SYSOUT=*
