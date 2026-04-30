//* ============================================================
//* ARQUIVO      : EBJSNAP.jcl
//* CAMINHO LOCAL: jcl/batch/EBJSNAP.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJSNAP)
//*
//* FINALIDADE:
//*   Capturar snapshot dos saldos de todas as contas do KSDS
//*   e gravar em nova geracao GDG (ARQ.SALDO.GDG(+1)).
//*   O snapshot serve como baseline para o CHECK3 da conciliacao.
//*
//* POSICAO NA CADEIA DIARIA:
//*   EBJCUTE (EOFI) --> EBJSNAP --> EBJCONC (conciliacao)
//*   O snapshot deve ser tirado APOS o corte contabil (EOFI)
//*   para representar o estado final do dia.
//*
//* O QUE ESTE JOB FAZ:
//*   1. Le todas as contas do KSDS por READ NEXT (sequencial)
//*   2. Para cada conta: copia SNP-AGENCIA, SNP-NUM-CONTA,
//*      SNP-SALDO e SNP-DATA (data do dia)
//*   3. Grava em SALDO.GDG(+1) - nova geracao do dia
//*   4. Acumula WS-TOTAL-SALDO para DISPLAY no SYSOUT
//*
//* GDG DE SALDO:
//*   GDG(0)  = snapshot mais recente (este dia)
//*   GDG(-1) = snapshot do dia anterior
//*   Retencao controlada pela base GDG (EBDEFGDG).
//*
//* CODIGOS DE RETORNO:
//*   RC 0 = snapshot gerado com sucesso
//*   RC 4 = KSDS de contas vazio - snapshot vazio gerado
//*   RC 8 = erro de I/O
//* ============================================================
//EBJSALD  JOB ,'EMUNAH SNAP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: SNAPSHOT DE SALDO (EBSNAP01) =====================
//*
//STEP1    EXEC PGM=EBSNAP01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*           Biblioteca contendo o modulo executavel EBSNAP01.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//*           VSAM KSDS de contas. Leitura sequencial por
//*           READ NEXT (ACCESS DYNAMIC) do inicio ao fim.
//SALDOUT  DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*           Auditoria do snapshot. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//*           WS-TOTAL-SALDO acumulado e exibido aqui ao final.
//SYSPRINT DD SYSOUT=*