//* ============================================================
//* ARQUIVO      : EBJCONC.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCONC.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCONC)
//*
//* FINALIDADE:
//*   Executar a conciliacao tres-vias (three-way reconciliation)
//*   do dia: compara contagem de lancamentos, liquidez (saldo
//*   calculado vs KSDS) e snapshot vs KSDS de contas.
//*
//* POSICAO NA CADEIA DIARIA:
//*   EBJSNAP --> EBJCONC --> EBJEOD
//*   O snapshot deve existir antes da conciliacao.
//*
//* REGISTROS GERADOS EM CONCIL.SEQ:
//*   H11 = cabecalho do arquivo
//*   D11 = detalhe CHECK1 (contagem lancamentos)
//*   D21 = detalhe CHECK2 (liquidez por conta)
//*   D31 = detalhe CHECK3 (snapshot vs KSDS)
//*   R11 = resultado CHECK1  R21 = resultado CHECK2
//*   R31 = resultado CHECK3
//*   T98 = rodape com divergencias  T99 = rodape final
//*
//* CODIGOS DE RETORNO:
//*   RC 0 = conciliacao OK - todos os checks passaram
//*   RC 4 = divergencia em CHECK3 (alertante, nao bloqueante)
//*   RC 8 = divergencia em CHECK1 (bloqueante - nao prosseguir)
//* ============================================================
//EBJCONC  JOB ,'EMUNAH CONC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: CONCILIACAO TRES-VIAS (EBCONC01) =================
//*
//STEP1    EXEC PGM=EBCONC01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*           Biblioteca contendo o modulo executavel EBCONC01.
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//*           VSAM ESDS de lancamentos validados e postados.
//*           DDNAME MOVTIN: entrada principal da conciliacao.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//*           VSAM KSDS de contas para CHECK2 (liquidez).
//SALDOIN  DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(0),DISP=SHR
//*           GDG de saldo do dia anterior (geracao 0=mais recente).
//*           Opcional: se ausente, CHECK2 usa saldo inicial zero.
//SNAPIN   DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(0),DISP=SHR
//*           GDG de snapshot gerado pelo EBJSNAP no inicio do dia.
//*           Usado no CHECK3 (snapshot vs KSDS atual).
//CONCOUT  DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//*           Arquivo de saida com o relatorio de conciliacao.
//*           LRECL=132 comporta registros H/D/R/T do CPCONC001.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*           Auditoria do processamento. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*