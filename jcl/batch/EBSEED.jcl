//* ============================================================
//* ARQUIVO      : EBSEED.jcl
//* CAMINHO LOCAL: jcl/batch/EBSEED.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBSEED)
//*
//* FINALIDADE:
//*   Carga inicial dos dados seed nos VSAM KSDS do laboratorio.
//*   Executado UMA UNICA VEZ apos EBALLOC para popular os KSDS
//*   vazios com os dados de referencia do laboratorio.
//*
//* DIFERENCA ENTRE EBSEED E EBJCLLD:
//*   EBSEED  = primeiro load, KSDS recem-alocados vazios.
//*             Usa DISP=OLD nos KSDS (acesso exclusivo).
//*   EBJCLLD = carga operacional, KSDS ja populados.
//*             Usa DISP=SHR nos KSDS (acesso compartilhado).
//*
//* PRE-REQUISITOS:
//*   - EBALLOC ja executado (KSDS alocados e catalogados)
//*   - SEED.CLIENTES.SEQ e SEED.CONTAS.SEQ disponibilizados
//*
//* O QUE ESTE JOB FAZ:
//*   1. Le SEED.CLIENTES.SEQ e grava no CLIENTE.KSDS
//*   2. Le SEED.CONTAS.SEQ e grava no CONTA.KSDS
//*   3. Registra a execucao na auditoria
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = seed carregado com sucesso
//*   RC 8  = duplicata detectada (dado seed repetido)
//*   RC 12 = erro critico de abertura ou KSDS inacessivel
//* ============================================================
//EBSEED   JOB ,'EMUNAH SEED',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: CARGA SEED (EBCLLOAD) ============================
//*
//STEP1    EXEC PGM=EBCLLOAD
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*           Biblioteca contendo o modulo executavel EBCLLOAD.
//CLIENTIN DD DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ,DISP=SHR
//*           Arquivo seed de clientes (RECFM=FB, LRECL=80).
//*           Layout CPCLI001. DDNAME CLIENTIN esperado pelo prog.
//CONTAIN  DD DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ,DISP=SHR
//*           Arquivo seed de contas (RECFM=FB, LRECL=100).
//*           Layout CPCNT001. DDNAME CONTAIN esperado pelo prog.
//CLIENTE  DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=OLD
//*           VSAM KSDS de clientes. DISP=OLD = acesso exclusivo.
//*           Garante que nenhum outro job acessa o KSDS durante
//*           a carga inicial, evitando inconsistencias.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=OLD
//*           VSAM KSDS de contas. DISP=OLD = acesso exclusivo.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*           Auditoria da carga seed. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//*           Saida operacional do programa (totais de carga).