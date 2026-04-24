//* ============================================================
//* ARQUIVO      : EBJSMKH.jcl
//* CAMINHO LOCAL: jcl/hml/EBJSMKH.jcl
//* HOST / PDS   : Z77948.EMUNAH.HML.JCL(EBJSMKH)
//*
//* FINALIDADE:
//*   Smoke test do ambiente HML: valida que o executavel
//*   EBSMKH01 esta acessivel na LOADLIB e que o JCL esta
//*   corretamente configurado para o ambiente.
//*
//* O QUE ESTE JOB FAZ:
//*   Executa EBSMKH01, que:
//*   1. Captura data/hora via FUNCTION CURRENT-DATE
//*   2. Exibe identificacao do ambiente HML no SYSOUT
//*   3. Retorna RC=0 se tudo ok
//*
//* QUANDO EXECUTAR:
//*   Como primeiro job de qualquer bateria de testes em HML.
//*   RC=0 libera execucao dos testes funcionais subsequentes.
//*   RC != 0 indica problema de ambiente (LOADLIB, JCL, RACF).
//*
//* NOTA SOBRE STEPLIB:
//*   Substituir DEV.LOADLIB por Z77948.EMUNAH.HML.LOADLIB
//*   quando a biblioteca de homologacao for criada e populada
//*   com os executaveis promovidos de DEV.
//* ============================================================
//EBJSMKH  JOB ,'EMUNAH HML SMOKE',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*           NOTIFY=&SYSUID: notifica o submissor ao terminar.
//*
//* === STEP1: SMOKE TEST (EBSMKH01) ============================
//*
//STEP1    EXEC PGM=EBSMKH01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*           LOADLIB de desenvolvimento. Substituir por
//*           Z77948.EMUNAH.HML.LOADLIB quando disponivel.
//SYSPRINT DD SYSOUT=*
//*           Mensagens do sistema.
//SYSOUT   DD SYSOUT=*
//*           Saida do DISPLAY no EBSMKH01:
//*           *** EMUNAH BANK LAB - SMOKE TEST HML ***
//*           PROGRAMA : EBSMKH01
//*           AMBIENTE : HML
//*           DATA     : DD/MM/AAAA
//*           HORA     : HH:MM:SS
//*           STATUS   : EXECUCAO OK