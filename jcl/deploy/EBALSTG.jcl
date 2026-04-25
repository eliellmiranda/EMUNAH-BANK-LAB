//* ============================================================
//* ARQUIVO      : EBALSTG.jcl
//* CAMINHO LOCAL: jcl/deploy/EBALSTG.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBALSTG)
//*
//* FINALIDADE:
//*   Alocar o dataset STAGE.ENTRADA.SEQ que recebe o arquivo
//*   de lancamentos do dia ANTES de promover para o operacional
//*   ARQ.ENTRADA.SEQ via EBJLOAD.
//*
//* QUANDO USAR:
//*   - Setup inicial do ambiente (executado UMA UNICA VEZ)
//*   - Apos EBRESET ter deletado o STAGE
//*   - Diagnostico de "DATASET NOT FOUND" no EBJWAIT
//*
//* RELACAO COM A CADEIA DIARIA:
//*   STAGE alimentado externamente -> EBJWAIT (file-watcher)
//*     -> EBJLOAD (IEBGENER copia STAGE para ARQ) -> EBJVALD ...
//*
//* DCB:
//*   RECFM=FB  LRECL=120  BLKSIZE=0 (system-determined)
//*   Mesmo layout de ARQ.ENTRADA.SEQ (registro CPLCT001).
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = STAGE alocado e catalogado com sucesso
//*   RC 12 = ja existe (esperado em re-execucao apos reset)
//* ============================================================
//EBALSTG  JOB ,'EMUNAH ALOC STAGE',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP ALOC: ALOCAR STAGE.ENTRADA.SEQ =====================
//*
//ALOC     EXEC PGM=IEFBR14
//STAGE    DD DSN=Z77948.EMUNAH.STAGE.ENTRADA.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Recebe o arquivo de lancamentos do dia (deposito
//*           externo - SFTP, NDM, upload manual). Validado pelo
//*           EBJWAIT (existe + nao vazio) e copiado para
//*           ARQ.ENTRADA.SEQ pelo EBJLOAD via IEBGENER.
//SYSPRINT DD SYSOUT=*
