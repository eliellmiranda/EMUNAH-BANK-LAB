//* ============================================================
//* ARQUIVO      : EBBUILD.jcl
//* CAMINHO LOCAL: jcl/compile/EBBUILD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBBUILD)
//*
//* FINALIDADE:
//*   Compilar e link-editar um unico programa COBOL em um
//*   job, usando a procedure catalogada IBM IGYWCL.
//*
//* QUANDO USAR ESTE JCL:
//*   - Build rapido de um programa isolado apos correcao
//*   - Alternativa ao EBDEPLOY quando so um fonte mudou
//*   - Para alterar o programa compilado: editar COBOL.SYSIN
//*     e LKED.SYSLMOD com o nome do programa desejado
//*
//* PROCEDURE IGYWCL:
//*   Procedure IBM catalogada que encadeia:
//*   1. COBOL step: IGYCRCTL (compilador Enterprise COBOL)
//*      - Le fonte de COBOL.SYSIN
//*      - Resolve COPYs de COBOL.SYSLIB
//*      - Gera objeto em &&OBJSET (temporario)
//*   2. LKED step: IEWBLINK (binder/link-editor)
//*      - Le objeto de &&OBJSET
//*      - Grava executavel em LKED.SYSLMOD
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = compilacao e link sem erros
//*   RC 4  = avisos de compilacao (aceitar se SYSPRINT ok)
//*   RC 8  = erros de compilacao - modulo NAO gerado
//*   RC 12 = erros severos - verificar SYSPRINT imediatamente
//* ============================================================
//EBBUILD  JOB ,'EMUNAH BUILD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CL: COMPILE + LINK (IGYWCL) ========================
//*   Para compilar outro programa: substituir EBCLLOAD pelo
//*   nome do programa desejado em SYSIN e SYSLMOD.
//*
//CL       EXEC IGYWCL
//COBOL.SYSIN   DD DSN=Z77948.EMUNAH.DEV.COBOL(EBCLLOAD),DISP=SHR
//*              Fonte COBOL a compilar (membro do PDS de fontes).
//COBOL.SYSLIB  DD DSN=Z77948.EMUNAH.DEV.COPY,DISP=SHR
//*              Biblioteca de copybooks resolvida pelo compilador
//*              ao processar cada instrucao COPY no fonte.
//LKED.SYSLMOD  DD DSN=Z77948.EMUNAH.DEV.LOADLIB(EBCLLOAD),DISP=SHR
//*              Destino do modulo executavel na LOADLIB.
//*              O membro deve ter o mesmo nome do programa.
//LKED.SYSPRINT DD SYSOUT=*
//*              Relatorio do link-editor: mapa de memoria,
//*              modulos incluidos e diagnostico de erros.