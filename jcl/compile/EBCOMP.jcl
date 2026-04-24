//* ============================================================
//* ARQUIVO      : EBCOMP.jcl
//* CAMINHO LOCAL: jcl/compile/EBCOMP.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBCOMP)
//*
//* FINALIDADE:
//*   Compilar o fonte COBOL e gerar o modulo objeto temporario
//*   para link-edicao posterior pelo EBLINK.
//*
//* RELACAO COM OUTROS JCLs:
//*   EBCOMP (compila) + EBLINK (linka) = equivalente a EBBUILD
//*   Use EBCOMP+EBLINK quando quiser inspecionar o objeto antes
//*   de linkar, ou quando o link exigir bibliotecas adicionais.
//*
//* COMPILADOR: IGYCRCTL (IBM Enterprise COBOL)
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = compilacao sem erros
//*   RC 4  = avisos (W) - objeto gerado mas revisar SYSPRINT
//*   RC 8  = erros (E/S) - objeto NAO confiavel, nao linkar
//*   RC 12 = erros severos - investigar SYSPRINT antes de rerun
//* ============================================================
//EBCOMP   JOB ,'EMUNAH COMP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: COMPILACAO COBOL (IGYCRCTL) ======================
//*
//STEP1    EXEC PGM=IGYCRCTL
//SYSIN    DD DSN=Z77948.EMUNAH.DEV.COBOL(EBCLLOAD),DISP=SHR
//*           Fonte COBOL a compilar. Para compilar outro programa,
//*           substituir EBCLLOAD pelo nome do membro desejado.
//SYSLIB   DD DSN=Z77948.EMUNAH.DEV.COPY,DISP=SHR
//*           Biblioteca de copybooks. O compilador procura aqui
//*           cada COPY encontrado no fonte COBOL.
//SYSLIN   DD DSN=&&OBJSET,DISP=(,PASS),UNIT=SYSDA,
//             SPACE=(TRK,(1,1)),DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//*           Dataset temporario com o modulo objeto gerado.
//*           DISP=(,PASS): criado neste step e passado para o
//*           proximo job/step (EBLINK) via catalogo temporario.
//*           Deletado automaticamente ao fim do job se nao consumido.
//SYSPRINT DD SYSOUT=*
//*           Listagem detalhada da compilacao: codigo-fonte
//*           numerado, mensagens de diagnostico (W/E/S/U),
//*           mapa de dados e estatisticas do compilador.
//SYSOUT   DD SYSOUT=*
//*           Saida operacional do compilador.