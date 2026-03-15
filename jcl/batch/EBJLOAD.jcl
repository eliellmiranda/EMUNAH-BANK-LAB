//* ------------------------------------------------------------
//* JOB: EBJLOAD
//* FINALIDADE:
//* Executar o programa EBCLLOAD para realizar a carga inicial
//* dos arquivos do laboratorio EMUNAH.
//*
//* FLUXO ESPERADO:
//* 1. Ler o arquivo sequencial de clientes.
//* 2. Ler o arquivo sequencial de contas.
//* 3. Gravar os clientes no VSAM de clientes.
//* 4. Gravar as contas no VSAM de contas.
//* 5. Registrar eventos no arquivo de auditoria.
//* ------------------------------------------------------------
//EBJLOAD  JOB ,'EMUNAH LOAD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//* Define o job de carga inicial do laboratorio.
//STEP1    EXEC PGM=EBCLLOAD
//* Executa o programa responsavel pela carga.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca onde esta o modulo executavel EBCLLOAD.
//CLIENTIN DD DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ,DISP=SHR
//* Arquivo sequencial de entrada com os registros de clientes.
//CONTAIN  DD DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ,DISP=SHR
//* Arquivo sequencial de entrada com os registros de contas.
//CLIENTE  DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//* Arquivo VSAM KSDS de clientes.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* Arquivo VSAM KSDS de contas.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Arquivo de auditoria do processamento.
//SYSOUT   DD SYSOUT=*
//* Saida geral do step para o spool.
//SYSPRINT DD SYSOUT=*
//* Saida detalhada e mensagens do programa.
