//* ============================================================
//* ARQUIVO      : EBJEOD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJEOD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJEOD)
//*
//* FINALIDADE:
//* Fechamento diario (End-Of-Day): consolida o dia contabil,
//* gera relatorio de fechamento e marca CTL.STATUS = CLOSED.
//* Utiliza o programa EBCTL01 para garantir a integridade.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJCONC (conciliacao) --> EBJEOD --> Fim do ciclo
//*
//* O QUE ESTE JOB FAZ:
//* 0. CHKSTAT  - Valida se o status atual e EOFI.
//* 1. FECHTO   - EBJEOD01 gera relatorio FECHOUT e totaliza contas.
//* 2. CLOSDAY  - EBCTL01 marca o status final como CLOSED.
//*
//* CODIGOS DE RETORNO:
//* RC 0  = Dia fechado com sucesso - CLOSED gravado.
//* RC 8  = Erro na transicao de status ou divergencia no EOD.
//* RC 12 = Falha critica em arquivos - investigar antes de rerun.
//* ============================================================
//EBJEOD   JOB ,'EMUNAH EOD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKSTAT: GARANTIR ESTADO EOFI =====================
//* Garante que o fechamento so inicie se o corte contabil
//* ja tiver sido realizado (status EOFI).
//*
//CHKSTAT  EXEC PGM=EBCTL01,PARM='CHK,EOFI'
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//*
//* === STEP FECHTO: FECHAMENTO DIARIO (EBJEOD01) ==============
//* Executa somente se a checagem de status retornou RC=0.
//*
//FECHTO   EXEC PGM=EBJEOD01,COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca contendo o modulo executavel EBJEOD01.
//CONCIN   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=SHR
//* Arquivo de conciliacao gerado pelo EBJCONC.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* VSAM KSDS de contas para totalizacao do dia.
//SALDOIN  DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(-1),DISP=SHR
//* GDG de saldo do dia anterior. (-1) evita a leitura do 
//* snapshot de hoje gerado pelo EBJSNAP.
//FECHOUT  DD DSN=Z77948.EMUNAH.ARQ.FECHTO.SEQ,DISP=OLD
//* Relatorio de fechamento do dia. (Requer alocacao previa)
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria do fechamento. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
//* === STEP CLOSDAY: GRAVAR STATUS = CLOSED ===================
//* COND=(0,NE): executa SOMENTE se os passos anteriores
//* terminaram com sucesso.
//* O programa EBCTL01 valida a transicao EOFI -> CLOSED.
//*
//CLOSDAY  EXEC PGM=EBCTL01,PARM='UPD,CLOSED',COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//* DISP=OLD garante controle exclusivo para a gravacao final.
//*