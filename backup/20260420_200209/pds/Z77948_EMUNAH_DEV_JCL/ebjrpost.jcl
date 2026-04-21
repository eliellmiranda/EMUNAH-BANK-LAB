//* ------------------------------------------------------------
//* ARQUIVO      : EBJRPOST.jcl
//* CAMINHO LOCAL: jcl/batch/EBJRPOST.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJRPOST)
//* FINALIDADE:
//* Postar nas contas os lancamentos reprocessados do dia
//* (rejeitos que foram corrigidos pelo EBJREPR).
//*
//* Fecha o ciclo de rejeitos: REJEITOS -> REPROCESSA -> POSTA.
//*
//* FLUXO ESPERADO:
//* 1. Ler MOVTIN a partir de ARQ.REPR.LANCTO.SEQ.
//* 2. Localizar CLIENTE e CONTA.
//* 3. Atualizar os saldos e gravar auditoria.
//*
//* OBS: reutiliza EBPOST01. MOVTIN passa a ser sequencial
//* (PS) ao inves de ESDS. Depende de EBPOST01 estar com
//* SELECT em ORGANIZATION SEQUENTIAL (leitura agnostica
//* entre ESDS e PS).
//* ------------------------------------------------------------
//EBJRPOST JOB ,'EMUNAH RPOST',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBPOST01
//* Programa de postagem (reutilizado do EBJPOST).
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca do executavel EBPOST01.
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,DISP=SHR
//* Entrada de lancamentos reprocessados (saida do EBJREPR).
//CLIENTE  DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//* Cadastro master de clientes.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* Cadastro master de contas.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria da execucao da postagem de reprocessados.
//SYSOUT   DD SYSOUT=*
//* Saida geral do programa.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas.
