//* ------------------------------------------------------------
//* ARQUIVO      : EBJPOST.jcl
//* CAMINHO LOCAL: jcl/batch/EBJPOST.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJPOST)
//* FINALIDADE:
//* Aplicar nas contas os lancamentos ja validados.
//*
//* FLUXO ESPERADO:
//* 1. Ler MOVTIN a partir de ARQ.LANCTO.ESDS.
//* 2. Localizar CLIENTE e CONTA.
//* 3. Atualizar os saldos e gravar auditoria.
//* ------------------------------------------------------------
//EBJPOST  JOB ,'EMUNAH POST',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBPOST01
//* Programa de postagem dos lancamentos validos.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca do executavel EBPOST01.
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* Entrada de movimentos ja validados.
//CLIENTE  DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//* Cadastro master de clientes.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* Cadastro master de contas.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria da execucao da postagem.
//SYSOUT   DD SYSOUT=*
//* Saida geral do programa.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas.