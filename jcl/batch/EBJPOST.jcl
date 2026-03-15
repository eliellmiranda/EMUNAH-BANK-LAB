//* ------------------------------------------------------------
//* JOB: EBJPOST
//* FINALIDADE:
//* Executar o programa EBPOST01 para processar os lancamentos
//* de entrada do laboratorio EMUNAH.
//*
//* FLUXO ESPERADO:
//* 1. Ler os movimentos de entrada do dia.
//* 2. Localizar a conta correspondente.
//* 3. Aplicar credito ou debito.
//* 4. Registrar as ocorrencias em auditoria.
//* 5. Gerar mensagens e relatorio de processamento.
//* ------------------------------------------------------------
//EBJPOST  JOB ,'EMUNAH POST',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//* Define o job de processamento dos lancamentos.
//STEP1    EXEC PGM=EBPOST01
//* Executa o programa responsavel pela postagem.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca onde esta o modulo executavel EBPOST01.
//MOVTIN   DD DSN=Z77948.EMUNAH.ENTRADA.LANC.D0.SEQ,DISP=SHR
//* Arquivo sequencial de entrada com os lancamentos do dia.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* Arquivo VSAM KSDS de contas a ser consultado e atualizado.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Arquivo sequencial de auditoria do processamento.
//SYSOUT   DD SYSOUT=*
//* Saida geral do step para o spool.
//SYSPRINT DD SYSOUT=*
//* Saida detalhada, relatorio e mensagens do programa.