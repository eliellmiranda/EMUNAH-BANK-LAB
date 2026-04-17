//* ------------------------------------------------------------
//* ARQUIVO      : EBSEED.jcl
//* CAMINHO LOCAL: jcl/batch/EBSEED.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBSEED)
//* FINALIDADE:
//* Executar a carga inicial dos arquivos seed para os KSDS.
//*
//* FLUXO ESPERADO:
//* 1. Ler CLIENTES.SEQ e CONTAS.SEQ.
//* 2. Chamar o programa EBCLLOAD.
//* 3. Popular CLIENTE.KSDS e CONTA.KSDS.
//* 4. Registrar a execucao na auditoria.
//* ------------------------------------------------------------
//EBSEED   JOB ,'EMUNAH SEED',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBCLLOAD
//* Programa de carga inicial.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca onde esta o executavel EBCLLOAD.
//CLIENTIN DD DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ,DISP=SHR
//* Dataset de entrada com os clientes seed.
//CONTAIN  DD DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ,DISP=SHR
//* Dataset de entrada com as contas seed.
//CLIENTE  DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=OLD
//* KSDS de clientes que sera carregado.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=OLD
//* KSDS de contas que sera carregado.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria textual da execucao.
//SYSOUT   DD SYSOUT=*
//* Saida geral do programa.
