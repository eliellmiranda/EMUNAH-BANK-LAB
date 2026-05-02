//* ============================================================
//* ARQUIVO      : EBJSNAP.jcl
//* CAMINHO LOCAL: jcl/batch/EBJSNAP.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJSNAP)
//*
//* FINALIDADE:
//* Capturar snapshot dos saldos de todas as contas do KSDS
//* e gravar em nova geracao GDG (ARQ.SALDO.GDG(+1)).
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJCUTE (EOFI) --> EBJSNAP --> EBJCONC (conciliacao)
//* O snapshot deve ser tirado APOS o corte contabil (EOFI)
//* para representar o estado final do dia.
//*
//* CODIGOS DE RETORNO:
//* RC 0 = snapshot gerado com sucesso
//* RC 4 = KSDS de contas vazio - snapshot vazio gerado
//* RC 8 = dia nao esta em EOFI ou erro de I/O
//* ============================================================
//EBJSNAP  JOB ,'EMUNAH SNAP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKSTAT: GARANTIR CORTE CONTABIL (EOFI) ===========
//* Valida se o status e EOFI antes de "fotografar" os saldos.
//* Impede snapshot prematuro com o banco ainda aberto.
//*
//CHKSTAT  EXEC PGM=EBCTL01,PARM='CHK,EOFI'
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//*
//* === STEP SNAP: SNAPSHOT DE SALDO (EBSNAP01) =================
//* Executa somente se a checagem de status retornou RC=0.
//*
//SNAP     EXEC PGM=EBSNAP01,COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca contendo o modulo executavel EBSNAP01.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* VSAM KSDS de contas consultado sequencialmente.
//SALDOUT  DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(+1),
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Snapshot do dia. Torna-se a geracao (0) ao fim do job.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria do snapshot. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//* Exibe o WS-TOTAL-SALDO para conferencia rapida no spool.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas e diagnostico do sistema.