//* ============================================================
//* ARQUIVO      : EBBUILD.jcl
//* CAMINHO LOCAL: jcl/compile/EBBUILD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBBUILD)
//*
//* FINALIDADE:
//*   Compilar e link-editar UM programa COBOL isolado.
//*   Build rapido para correcoes pontuais.
//*
//* QUANDO USAR:
//*   - Apos editar 1 fonte e querer testar a compilacao
//*   - Build rapido sem rodar o pipeline completo (EBDEPLOY)
//*
//* COMO TROCAR DE PROGRAMA:
//*   Substituir EBPCHK01 pelo nome desejado em DOIS lugares:
//*     1. COBOL.SYSIN  -> membro do fonte a compilar
//*     2. LKED.SYSLMOD -> membro de saida na LOADLIB
//*   Os dois nomes DEVEM ser iguais (convencao do projeto).
//*
//* PROCEDURE IGYWCL (catalogada IBM):
//*   Step COBOL: IGYCRCTL (Enterprise COBOL) -> &&OBJSET temp
//*   Step LKED : IEWBLINK (binder)           -> SYSLMOD
//*
//* ESTE JCL NAO EXECUTA O PROGRAMA.
//*   DDs de runtime (CLIENTIN, CONTAIN, CLIENTE, CONTA, AUDIT)
//*   ficam em JCL separado de execucao (EBRUN ou similar).
//*   Build e execucao sao responsabilidades distintas.
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = compile e link OK
//*   RC 4  = warnings (revisar SYSPRINT, geralmente aceitavel)
//*   RC 8  = erros de compilacao - modulo NAO gerado
//*   RC 12 = erros severos - LKED sera FLUSH
//* ============================================================
//EBBUILD  JOB ,'EMUNAH BUILD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CL: COMPILE + LINK (IGYWCL) ========================
//CL       EXEC IGYWCL
//*
//* --- Entradas do compilador ---
//COBOL.SYSIN    DD DSN=Z77948.EMUNAH.DEV.COBOL(EBPCHK01),DISP=SHR
//*               Fonte COBOL a compilar.
//COBOL.SYSLIB   DD DSN=Z77948.EMUNAH.DEV.COPY,DISP=SHR
//*               Biblioteca de copybooks. Toda instrucao COPY
//*               do fonte e resolvida lendo membros deste PDS.
//*               IMPORTANTE: copybooks alterados localmente
//*               precisam ser sincronizados aqui antes do build.
//*
//* --- Saida do link-editor ---
//LKED.SYSLMOD   DD DSN=Z77948.EMUNAH.DEV.LOADLIB(EBPCHK01),DISP=SHR
//*               Modulo executavel resultante. Membro deve ter
//*               o mesmo nome do programa (PROGRAM-ID).
//*
//* --- Relatorios ---
//COBOL.SYSPRINT DD SYSOUT=*
//*               Listagem do compilador: fonte expandido com
//*               COPYs resolvidos, mapa de WORKING-STORAGE,
//*               cross-reference e diagnosticos (IGY...).
//*               Primeiro lugar a olhar quando RC <> 0.
//LKED.SYSPRINT  DD SYSOUT=*
//*               Relatorio do binder: modulos incluidos, mapa
//*               de memoria e diagnosticos (IEW...).