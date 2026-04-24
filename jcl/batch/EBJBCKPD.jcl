//* ============================================================
//* ARQUIVO      : EBJBCKPD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJBCKPD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJBCKPD)
//*
//* FINALIDADE:
//*   Backup logico do ambiente antes da cadeia batch principal.
//*   Gera uma nova geracao GDG (+1) para cada base, permitindo
//*   restauracao do estado pre-batch via geracoes GDG(-N).
//*
//* O QUE ESTE JOB FAZ:
//*   1. Exporta VSAM de clientes -> BKP.CLIENTE.GDG(+1)
//*   2. Exporta VSAM de contas   -> BKP.CONTA.GDG(+1)
//*   3. Copia auditoria corrente -> BKP.AUDIT.GDG(+1)
//*
//* RESTAURACAO:
//*   Em caso de falha na cadeia, use IDCAMS REPRO com
//*   INFILE apontando para GDG(-1) para reverter o KSDS
//*   ao estado pre-batch do dia anterior.
//*
//* POSICAO NA CADEIA:
//*   Executar ANTES de EBJSOD / EBJPRECK (inicio do dia).
//* ============================================================
//EBJBACKP JOB ,'EMUNAH BKUP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP BKPCLI: BACKUP VSAM CLIENTES =======================
//*   IDCAMS REPRO copia todos os registros do KSDS de clientes
//*   para uma nova geracao do GDG de backup.
//*
//BKPCLI   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//INFILE   DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//*           VSAM KSDS de clientes - fonte do backup.
//OUTFILE  DD DSN=Z77948.EMUNAH.ARQ.BKP.CLIENTE.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=80,BLKSIZE=0)
//*           Nova geracao GDG. MODEL.DSCB herda atributos
//*           definidos na base GDG pelo EBDEFGDG.
//SYSIN    DD *
  REPRO INFILE(INFILE) OUTFILE(OUTFILE)
  IF LASTCC > 0 THEN -
    SET MAXCC = 8
/*
//*
//* === STEP BKPCNT: BACKUP VSAM CONTAS =========================
//*   Executado somente se BKPCLI terminou com RC <= 4.
//*   COND=(4,LT): pula o step se RC do step anterior > 4.
//*
//BKPCNT   EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//INFILE   DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//*           VSAM KSDS de contas - fonte do backup.
//OUTFILE  DD DSN=Z77948.EMUNAH.ARQ.BKP.CONTA.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=100,BLKSIZE=0)
//*           Nova geracao GDG do backup de contas.
//SYSIN    DD *
  REPRO INFILE(INFILE) OUTFILE(OUTFILE)
  IF LASTCC > 0 THEN -
    SET MAXCC = 8
/*
//*
//* === STEP BKPAUD: SNAPSHOT DA AUDITORIA ======================
//*   IEBGENER copia o arquivo de auditoria corrente para GDG.
//*   Permite rastrear o historico de auditoria por data.
//*
//BKPAUD   EXEC PGM=IEBGENER,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=SHR
//*           Arquivo de auditoria corrente (fonte).
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.BKP.AUDIT.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Nova geracao GDG do backup de auditoria.
//SYSIN    DD DUMMY
//*           IEBGENER nao precisa de SYSIN para copia simples.