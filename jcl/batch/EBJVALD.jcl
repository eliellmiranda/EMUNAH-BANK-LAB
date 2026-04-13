//* ------------------------------------------------------------
//* JOB: EBJSALD
//* FINALIDADE:
//* Executar o programa EBSALD01 para processar a rotina de
//* saldo do laboratorio EMUNAH.
//*
//* FLUXO ESPERADO:
//* 1. Ler o arquivo mestre de contas.
//* 2. Consultar os dados necessarios para composicao do saldo.
//* 3. Atualizar ou consolidar o saldo das contas.
//* 4. Registrar eventos no arquivo de auditoria.
//* 5. Gerar mensagens e relatorio de processamento.
//* ------------------------------------------------------------
//EBJSALD  JOB ,'EMUNAH SALDO',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//* Define o job de processamento de saldo.
//STEP1    EXEC PGM=EBSALD01
//* Executa o programa responsavel pela rotina de saldo.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca onde esta o modulo executavel EBSALD01.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* Arquivo VSAM KSDS de contas usado na rotina de saldo.
//SALDIN   DD DSN=Z77948.EMUNAH.ARQ.SALDO.SEQ,DISP=SHR
//* Arquivo de entrada ou apoio para processamento de saldo.
//* Ajustar conforme a regra real implementada no programa.
//*SALDOUT  DD DSN=<HQL>.EMUNAH.ARQ.SALDO.OUT.SEQ,
//*             DISP=(NEW,CATLG,DELETE),
//*             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//*             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* DD SALDOUT desativado - arquivo de saida nao utilizado no momento.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Arquivo sequencial de auditoria do processamento.
//SYSOUT   DD SYSOUT=*
//* Saida geral do step para o spool.
//SYSPRINT DD SYSOUT=*
//* Saida detalhada, relatorio e mensagens do programa.