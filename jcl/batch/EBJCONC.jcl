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
//*
//* REGISTROS GERADOS EM CONCIL.SEQ:
//* H11 = cabecalho do arquivo
//* D11 = detalhe CHECK1 (contagem lancamentos)
//* D21 = detalhe CHECK2 (liquidez por conta)
//* D31 = detalhe CHECK3 (snapshot vs KSDS)
//* R11 = resultado CHECK1  R21 = resultado CHECK2
//* R31 = resultado CHECK3
//* T98 = rodape com divergencias  T99 = rodape final
//*
//* CODIGOS DE RETORNO:
//* RC 0 = conciliacao OK - todos os checks passaram
//* RC 4 = divergencia em CHECK3 (alertante, nao bloqueante)
//* RC 8 = dia nao esta EOFI (EBCTL01) ou divergencia no CHECK1
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
//* Biblioteca contendo o modulo executavel EBCONC01.
//ENTRIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* VSAM ESDS de lancamentos validados e postados.
//* DDNAME MOVTIN: entrada principal da conciliacao.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* VSAM KSDS de contas para CHECK2 (liquidez).
//SALDOIN  DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(0),DISP=SHR
//* GDG de saldo do dia anterior (geracao 0=mais recente).
//* Opcional: se ausente, CHECK2 usa saldo inicial zero.
//SNAPIN   DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(0),DISP=SHR
//* GDG de snapshot gerado pelo EBJSNAP no inicio do dia.
//* Usado no CHECK3 (snapshot vs KSDS atual).
//CONCOUT  DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=SHR
//* Arquivo de saida com o relatorio de conciliacao.
//* LRECL=132 comporta registros H/D/R/T do CPCONC001.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria do processamento. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
