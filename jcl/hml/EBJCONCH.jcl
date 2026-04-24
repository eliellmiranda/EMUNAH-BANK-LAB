//* ============================================================
//* ARQUIVO      : EBJCONCH.jcl
//* CAMINHO LOCAL: jcl/hml/EBJCONCH.jcl
//* HOST / PDS   : Z77948.EMUNAH.HML.JCL(EBJCONCH)
//*
//* FINALIDADE:
//*   Executar a conciliacao (EBCONC01) no ambiente de
//*   homologacao para validar o fluxo antes de promover a PRD.
//*
//* DIFERENCAS EM RELACAO AO JCL DE BATCH (EBJCONC):
//*   - NOTIFY=&SYSUID : notifica o submissor ao terminar
//*   - STEPLIB aponta para DEV.LOADLIB (ate HML.LOADLIB existir)
//*   - MOVTIN = ARQ.LANCTO.VALID.SEQ (PS, nao ESDS como em DEV)
//*   - CONCOUT usa DISP=OLD (sobrescreve; nao gera nova versao)
//*
//* NOTA SOBRE STEPLIB:
//*   Em producao, o STEPLIB deve apontar para Z77948.EMUNAH.HML.LOADLIB
//*   contendo os executaveis promovidos de DEV. Enquanto a HML.LOADLIB
//*   nao existir, usar DEV.LOADLIB como substituto temporario.
//* ============================================================
//EBJCONCH JOB ,'EMUNAH HML CONC',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*           NOTIFY=&SYSUID: envia mensagem ao TSO do submissor
//*           quando o job terminar (RC e nome do job).
//*
//* === STEP1: CONCILIACAO HML (EBCONC01) =======================
//*
//STEP1    EXEC PGM=EBCONC01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*           LOADLIB de desenvolvimento (substituir por HML.LOADLIB
//*           quando a biblioteca de HML for criada e populada).
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.VALID.SEQ,DISP=SHR
//*           Arquivo de movimentos validos em HML.
//*           Em DEV: seria ARQ.LANCTO.ESDS (VSAM ESDS).
//*           Em HML: usa arquivo sequencial equivalente (PS).
//CONCOUT  DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=OLD
//*           Resultado da conciliacao. DISP=OLD = sobrescreve.
//*           Em DEV/batch (EBJCONC): DISP=(NEW,CATLG,DELETE).
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*