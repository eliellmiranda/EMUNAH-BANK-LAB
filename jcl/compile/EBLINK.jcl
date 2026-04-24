//* ============================================================
//* ARQUIVO      : EBLINK.jcl
//* CAMINHO LOCAL: jcl/compile/EBLINK.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBLINK)
//*
//* FINALIDADE:
//*   Link-editar o modulo objeto gerado pelo EBCOMP e gravar
//*   o executavel final na LOADLIB do laboratorio.
//*
//* PRE-REQUISITO:
//*   EBCOMP deve ter executado com RC <= 4, gerando &&OBJSET.
//*   Se executado em job separado, &&OBJSET deve estar
//*   catalogado com DISP=PASS do job anterior.
//*
//* BINDER: IEWBLINK (IBM Program Management Binder)
//*   RENT = modulo reentrante (obrigatorio para CICS, recomendado
//*          para batch com REUS)
//*   REUS = modulo reutilizavel (pode ser carregado uma vez e
//*          reusado por multiplas tasks no mesmo address space)
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = link sem erros - executavel gerado
//*   RC 4  = avisos - executavel gerado, revisar SYSPRINT
//*   RC 8  = erros - executavel NAO gerado
//* ============================================================
//EBLINK   JOB ,'EMUNAH LINK',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: LINK-EDICAO (IEWBLINK) ==========================
//*
//STEP1    EXEC PGM=IEWBLINK,PARM='RENT,REUS'
//*           RENT = reentrante | REUS = reutilizavel
//SYSPRINT DD SYSOUT=*
//*           Relatorio do binder: mapa de memoria do modulo,
//*           secoes incluidas, referencias externas resolvidas
//*           e mensagens de diagnostico.
//SYSLIN   DD DSN=&&OBJSET,DISP=(OLD,DELETE)
//*           Modulo objeto recebido do EBCOMP via &&OBJSET.
//*           DISP=(OLD,DELETE): consome e deleta o temporario
//*           apos a link-edicao, liberando espaco em disco.
//SYSLMOD  DD DSN=Z77948.EMUNAH.DEV.LOADLIB(EBCLLOAD),DISP=SHR
//*           Destino do executavel na LOADLIB.
//*           O membro deve ter o mesmo nome do programa COBOL.
//SYSUT1   DD UNIT=SYSDA,SPACE=(TRK,(1,1))
//*           Area de trabalho temporaria interna do binder.
//*           Nao contem dados uteis ao usuario.