//* ============================================================
//* ARQUIVO      : EBCOMP.jcl
//* CAMINHO LOCAL: jcl/compile/EBCOMP.jcl
//* HOST / PDS   : ELIEL.EMUNAH.DEV.JCL(EBCOMP)
//*
//* FINALIDADE:
//*   Compilar o fonte COBOL, gerar o modulo objeto temporario
//*   e EXTRAIR O MAPA ASSEMBLY (HLASM) via parametro LIST.
//* ============================================================
//EBCOMP   JOB ,'EMUNAH COMP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: COMPILACAO COBOL COM ENGENHARIA REVERSA (LIST) ===
//*
//STEP1    EXEC PGM=IGYCRCTL,PARM='LIST'
//*             ^ Aqui esta a magica! O parametro LIST instrui o
//*               compilador a documentar a traducao para Assembly.
//SYSIN    DD DSN=ELIEL.EMUNAH.DEV.COBOL(EBCLLOAD),DISP=SHR
//*           Fonte COBOL a compilar (Nossa Cobaia).
//SYSLIB   DD DSN=ELIEL.EMUNAH.DEV.COPY,DISP=SHR
//*           Biblioteca de copybooks.
//SYSLIN   DD DSN=&&OBJSET,DISP=(,PASS),UNIT=SYSDA,
//             SPACE=(TRK,(1,1)),DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//*           Dataset temporario com o modulo objeto gerado.
//SYSPRINT DD SYSOUT=*
//*           E AQUI QUE VOCE VAI OLHAR! O SDSF vai mostrar nesta
//*           saida o seu codigo COBOL lado a lado com os
//*           registradores e mnemonicos do mainframe.
//SYSOUT   DD SYSOUT=*
