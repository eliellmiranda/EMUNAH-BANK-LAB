//* ============================================================
//* ARQUIVO      : EBJCONC.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCONC.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCONC)
//*
//* FINALIDADE:
//* Executar a conciliacao tres-vias (three-way reconciliation)
//* do dia: compara contagem de lancamentos, liquidez (saldo
//* calculado vs KSDS) e snapshot vs KSDS de contas.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJSNAP --> EBJCONC --> EBJEOD
//* O snapshot deve existir antes da conciliacao.
//*
//* O QUE ESTE JOB FAZ:
//* 0. Valida se o CTL.STATUS = EOFI (janelas fechadas)
//* 1. Executa EBCONC01 gerando relatorio em CONCIL.SEQ
//* ============================================================
//EBJCONC  JOB ,'EMUNAH CONC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKSTAT: GARANTIR CORTE CONTABIL (EOFI) ===========
//* Usa o EBCTL01 em modo leitura (CHK) para validar se o
//* status e EOFI. Impede que a conciliacao rode com o banco
//* aberto (OPEN/EOTI) ou ja finalizado (CLOSED).
//*
//CHKSTAT  EXEC PGM=EBCTL01,PARM='CHK,EOFI'
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//*
//* === STEP CONCIL: CONCILIACAO TRES-VIAS (EBCONC01) ==========
//* Executa somente se a checagem de status retornou RC=0.
//*
//CONCIL   EXEC PGM=EBCONC01,COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*
//* --- ARQUIVOS DE MOVIMENTACAO (ENTRADAS E REJEITOS) ---
//ENTRIN   DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,DISP=SHR
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//REJEIT   DD DSN=Z77948.EMUNAH.ARQ.REJEITO.SEQ,DISP=SHR
//*
//* --- ARQUIVOS DE CONTAS E SALDOS ---
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//SALDOIN  DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(0),DISP=SHR
//*
//* --- ARQUIVOS DE SAIDA E AUDITORIA ---
//CONCOUT  DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=SHR
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*